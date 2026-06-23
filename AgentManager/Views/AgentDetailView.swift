import SwiftUI

/// Detail for the selected agent: title, description, and the full prompt.
/// The prompt sits in a scrollable region so long text stays readable.
struct AgentDetailView: View {
    let agent: Agent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(agent.title)
                    .font(.title2.weight(.semibold))

                Text(agent.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text("Prompt")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(agent.prompt)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    AgentDetailView(agent: SeedAgents.implementer)
        .frame(width: 320, height: 360)
}
