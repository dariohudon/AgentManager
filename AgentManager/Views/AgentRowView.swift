import SwiftUI

/// A single row in the agent navigator: the agent's name, plus a short
/// description only when there is real (non-placeholder) text — empty or
/// dash-only descriptions are not rendered, keeping the list calm.
struct AgentRowView: View {
    let agent: Agent

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(agent.name)
                .font(.body)

            if let description = agent.description.sanitizedForDisplay {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 1)
    }
}

#Preview {
    AgentRowView(agent: SeedAgents.architect)
        .frame(width: 200)
        .padding()
}
