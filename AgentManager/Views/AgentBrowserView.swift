import SwiftUI

/// List/detail browser for the agent vault, sized for the menu bar window.
/// Shows a sidebar of agents (name + short description) and a detail pane for
/// the selected agent. Falls back to a simple empty state when there are no
/// agents.
struct AgentBrowserView: View {
    let agents: [Agent]

    @State private var selectedAgentID: Agent.ID?

    var body: some View {
        if agents.isEmpty {
            emptyState
        } else {
            NavigationSplitView {
                List(agents, selection: $selectedAgentID) { agent in
                    AgentRowView(agent: agent)
                }
                .navigationTitle("Agents")
                .frame(minWidth: 200)
            } detail: {
                if let agent = selectedAgent {
                    AgentDetailView(agent: agent)
                } else {
                    selectPrompt
                }
            }
            .onAppear {
                if selectedAgentID == nil {
                    selectedAgentID = agents.first?.id
                }
            }
        }
    }

    private var selectedAgent: Agent? {
        agents.first { $0.id == selectedAgentID }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No agents yet")
                .font(.headline)

            Text("Your saved agents will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
    AgentBrowserView(agents: SeedAgents.all)
        .frame(width: 520, height: 360)
}

#Preview("Empty") {
    AgentBrowserView(agents: [])
        .frame(width: 520, height: 360)
}
