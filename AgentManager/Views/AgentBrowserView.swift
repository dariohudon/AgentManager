import SwiftUI

/// List/detail browser for the agent library, sized for the menu bar window.
///
/// Add/edit and delete-confirmation are shown as **inline modes** that replace
/// the browsing surface, rather than `.sheet`/`.confirmationDialog` modals.
/// Modals attached to a `MenuBarExtra` popover get dismissed when focus moves
/// or the popover resigns key, which made the editor vanish mid-edit; inline
/// modes are stable from both the menu bar panel and the hotkey-opened window.
struct AgentBrowserView: View {
    @Bindable var vault: AgentVault

    @State private var selectedAgentID: Agent.ID?
    @State private var mode: Mode = .browse

    /// Categories whose section is expanded. Empty by default, so every category
    /// starts collapsed each time the library opens. Not persisted across launches.
    @State private var expandedCategories: Set<String> = []

    /// What the surface is currently showing.
    private enum Mode {
        case browse
        case editor(AgentEditorMode)
        case confirmDelete(Agent)
    }

    var body: some View {
        switch mode {
        case .browse:
            browse
        case .editor(let editorMode):
            AgentEditorView(mode: editorMode, vault: vault) {
                mode = .browse
            }
        case .confirmDelete(let agent):
            deleteConfirmation(agent)
        }
    }

    // MARK: - Browse

    private var browse: some View {
        Group {
            if vault.agents.isEmpty {
                emptyState
            } else {
                NavigationSplitView {
                    sidebar
                } detail: {
                    if let agent = selectedAgent {
                        AgentDetailView(
                            agent: agent,
                            onEdit: { mode = .editor(.edit(agent)) },
                            onDelete: { mode = .confirmDelete(agent) }
                        )
                    } else {
                        selectPrompt
                    }
                }
            }
        }
    }

    /// Two-way binding for a category's expanded state, backed by
    /// `expandedCategories`. Categories are collapsed unless present in the set.
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

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedAgentID) {
                ForEach(groupedByCategory, id: \.category) { group in
                    DisclosureGroup(isExpanded: expansionBinding(for: group.category)) {
                        ForEach(group.agents) { agent in
                            AgentRowView(agent: agent)
                                .tag(agent.id)
                        }
                    } label: {
                        Text(group.category)
                            .font(.title3.weight(.bold))
                    }
                }
            }
            .navigationTitle("Agent Library")

            Divider()

            HStack {
                Button("New Agent", systemImage: "plus") {
                    mode = .editor(.add)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 200)
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
                Button("Cancel", role: .cancel) { mode = .browse }
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

    /// Agents grouped into categories (categories sorted alphabetically, agents
    /// sorted by name within each category).
    private var groupedByCategory: [(category: String, agents: [Agent])] {
        Dictionary(grouping: vault.agents, by: \.category)
            .map { (category: $0.key, agents: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category < $1.category }
    }

    private func confirmDelete(_ agent: Agent) {
        vault.delete(id: agent.id)
        if selectedAgentID == agent.id {
            selectedAgentID = vault.agents.first?.id
        }
        mode = .browse
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
                mode = .editor(.add)
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
