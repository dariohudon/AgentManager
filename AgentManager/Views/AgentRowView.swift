import SwiftUI

/// A single row in the agent list: the agent's name and a short description.
struct AgentRowView: View {
    let agent: Agent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(agent.name)
                .font(.body.weight(.medium))

            Text(agent.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AgentRowView(agent: SeedAgents.architect)
        .frame(width: 200)
        .padding()
}
