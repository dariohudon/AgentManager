import SwiftUI

/// A single row in the agent navigator: the agent's name, plus a short
/// description only when one exists (empty descriptions are not rendered, to
/// keep the list calm and free of placeholder clutter).
struct AgentRowView: View {
    let agent: Agent

    private var trimmedDescription: String {
        agent.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(agent.name)
                .font(.body)

            if !trimmedDescription.isEmpty {
                Text(trimmedDescription)
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
