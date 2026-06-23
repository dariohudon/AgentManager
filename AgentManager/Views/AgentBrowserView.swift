import SwiftUI

/// List/detail browser for the agent vault, sized for the menu bar window.
/// Shows a sidebar of agents (name + short description) with an add control,
/// and a detail pane for the selected agent with copy/edit/delete actions.
/// Falls back to a simple empty state when there are no agents.
struct AgentBrowserView: View {
    @Bindable var vault: AgentVault

    @State private var selectedAgentID: Agent.ID?
    @State private var editorMode: AgentEditorMode?
    @State private var agentPendingDeletion: Agent?

    var body: some View {
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
                            onEdit: { editorMode = .edit(agent) },
                            onDelete: { agentPendingDeletion = agent }
                        )
                    } else {
                        selectPrompt
                    }
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            AgentEditorView(mode: mode, vault: vault)
        }
        .confirmationDialog(
            "Delete this agent?",
            isPresented: deletionDialogBinding,
            presenting: agentPendingDeletion
        ) { agent in
            Button("Delete \(agent.name)", role: .destructive) {
                delete(agent)
            }
            Button("Cancel", role: .cancel) {}
        } message: { agent in
            Text("\"\(agent.title)\" will be removed from your vault. This can't be undone.")
        }
        .onAppear {
            if selectedAgentID == nil {
                selectedAgentID = vault.agents.first?.id
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedAgentID) {
                ForEach(groupedByCategory, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.agents) { agent in
                            AgentRowView(agent: agent)
                                .tag(agent.id)
                        }
                    }
                }
            }
            .navigationTitle("Agent Library")

            Divider()

            HStack {
                Button("New Agent", systemImage: "plus") {
                    editorMode = .add
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 200)
    }

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

    private var deletionDialogBinding: Binding<Bool> {
        Binding(
            get: { agentPendingDeletion != nil },
            set: { if !$0 { agentPendingDeletion = nil } }
        )
    }

    private func delete(_ agent: Agent) {
        vault.delete(id: agent.id)
        if selectedAgentID == agent.id {
            selectedAgentID = vault.agents.first?.id
        }
        agentPendingDeletion = nil
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No agents yet")
                .font(.headline)

            Text("Add an agent to start your vault.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("New Agent", systemImage: "plus") {
                editorMode = .add
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
