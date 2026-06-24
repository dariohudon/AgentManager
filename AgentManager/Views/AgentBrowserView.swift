import SwiftUI

/// The Agent Library surface: a native `NavigationSplitView` with a sidebar
/// navigator on the left and an agent inspection/detail region on the right.
///
/// Interaction architecture is **Browse → Inspect → Edit**:
/// - **Browse**: the sidebar (categories + agents). Selecting an agent always
///   returns the detail column to read-only inspect — navigating never drops
///   you into a form.
/// - **Inspect**: the default detail state (`.inspect`) — a read-focused view
///   of the selected agent. This is the resting experience.
/// - **Edit**: an intentional state (`.editor`) entered only via the Edit or
///   New Agent actions, never automatically.
///
/// Delete confirmation and app-level Settings are also detail-column states.
/// All flows stay inline (no `.sheet`/`.popover`/`.confirmationDialog`), which
/// is stable inside the `MenuBarExtra` popover and the hotkey window. This same
/// view backs both surfaces via `ContentView`; there is no menu-bar-only or
/// hotkey-only UI path.
struct AgentBrowserView: View {
    @Bindable var vault: AgentVault

    @State private var selectedAgentID: Agent.ID?
    @State private var detail: DetailMode = .inspect

    /// Categories whose section is expanded. Empty by default, so every category
    /// starts collapsed each time the library opens. Not persisted across launches.
    @State private var expandedCategories: Set<String> = []

    /// Lightweight local filter (agent name + category). Empty = show everything.
    @State private var searchText = ""

    /// What the detail (right) column is currently showing. `.inspect` is the
    /// default/read state; `.editor` is the intentional edit state.
    private enum DetailMode {
        case inspect
        case editor(AgentEditorMode)
        case confirmDelete(Agent)
        case settings
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailColumn
        }
        .onChange(of: selectedAgentID) {
            // Browsing to an agent always inspects it; editing is re-entered
            // deliberately via the Edit action.
            detail = .inspect
        }
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detailColumn: some View {
        switch detail {
        case .inspect:
            if let agent = selectedAgent {
                AgentDetailView(
                    agent: agent,
                    onEdit: { detail = .editor(.edit(agent)) },
                    onDuplicate: { duplicate(agent) },
                    onDelete: { detail = .confirmDelete(agent) }
                )
            } else if vault.agents.isEmpty {
                emptyState
            } else {
                selectPrompt
            }
        case .editor(let editorMode):
            AgentEditorView(mode: editorMode, vault: vault) {
                detail = .inspect
            }
        case .confirmDelete(let agent):
            deleteConfirmation(agent)
        case .settings:
            SettingsView(vault: vault) {
                detail = .inspect
            }
        }
    }

    // MARK: - Sidebar / navigator

    private var sidebar: some View {
        VStack(spacing: 0) {
            searchField

            Divider()

            List(selection: $selectedAgentID) {
                ForEach(groupedByCategory, id: \.category) { group in
                    if isSearching {
                        // While searching, render plain sections (no disclosure
                        // expand/collapse animation), which renders filtered
                        // results cleanly without overlap/bleed.
                        Section {
                            ForEach(group.agents) { agent in
                                AgentRowView(agent: agent)
                                    .tag(agent.id)
                            }
                        } header: {
                            categoryLabel(group.category)
                        }
                    } else {
                        DisclosureGroup(isExpanded: expansionBinding(for: group.category)) {
                            ForEach(group.agents) { agent in
                                AgentRowView(agent: agent)
                                    .tag(agent.id)
                            }
                        } label: {
                            categoryLabel(group.category)
                        }
                    }
                }
            }
            .navigationTitle("Agent Library")

            Divider()

            // Compact, quiet toolbar so creating/configuring never dominates
            // the browsing experience.
            HStack(spacing: 12) {
                Button {
                    detail = .editor(.add)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("New Agent")

                Spacer()

                Button {
                    detail = .settings
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 220)
    }

    /// Always-visible local search above the category list. Filters by agent
    /// name and category; while searching, matching categories auto-expand.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search agents", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    /// Category header label, sized to match the Settings category list rows
    /// (.body) and bold for navigation hierarchy. Shared by the browsing
    /// DisclosureGroup and the search-result Section.
    private func categoryLabel(_ category: String) -> some View {
        Text(category)
            .font(.body.weight(.bold))
    }

    /// Two-way binding for a category's expanded state (browsing only — search
    /// uses plain sections). Categories are collapsed unless present in
    /// `expandedCategories`.
    private func expansionBinding(for category: String) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(category) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category)
                } else {
                    expandedCategories.remove(category)
                }
            }
        )
    }

    // MARK: - Delete confirmation (inline)

    private func deleteConfirmation(_ agent: Agent) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text("Delete \"\(agent.title)\"?")
                .font(.headline)

            Text("This removes \(agent.name) from your library and can't be undone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Cancel", role: .cancel) { detail = .inspect }
                Button("Delete", role: .destructive) { confirmDelete(agent) }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var selectedAgent: Agent? {
        vault.agents.first { $0.id == selectedAgentID }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Agents (filtered by the search field on name + category) grouped into
    /// categories — categories sorted alphabetically, agents by name within
    /// each. Empty categories are dropped while searching.
    private var groupedByCategory: [(category: String, agents: [Agent])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let agents = query.isEmpty ? vault.agents : vault.agents.filter { agent in
            agent.name.lowercased().contains(query)
                || agent.category.lowercased().contains(query)
        }
        return Dictionary(grouping: agents, by: \.category)
            .map { (category: $0.key, agents: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category < $1.category }
    }

    private func confirmDelete(_ agent: Agent) {
        vault.delete(id: agent.id)
        if selectedAgentID == agent.id {
            selectedAgentID = nil
        }
        detail = .inspect
    }

    /// Duplicates the agent, expands the copy's category so it's visible,
    /// selects it, and returns to inspect mode.
    private func duplicate(_ agent: Agent) {
        guard let copy = vault.duplicate(id: agent.id) else { return }
        expandedCategories.insert(copy.category)
        selectedAgentID = copy.id
        detail = .inspect
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No agents yet")
                .font(.headline)

            Text("Add an agent to start your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("New Agent", systemImage: "plus") {
                detail = .editor(.add)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var selectPrompt: some View {
        Text("Select an agent")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("With agents") {
    AgentBrowserView(vault: AgentVault(agents: SeedAgents.all))
        .frame(width: 560, height: 420)
}

#Preview("Empty") {
    AgentBrowserView(vault: AgentVault(agents: []))
        .frame(width: 560, height: 420)
}
