import SwiftUI

/// Detail for the selected agent: title, description, and the full prompt.
/// The prompt sits in a scrollable region so long text stays readable, and a
/// Copy Prompt action copies only the prompt to the clipboard.
struct AgentDetailView: View {
    let agent: Agent

    @State private var didCopy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(agent.title)
                    .font(.title2.weight(.semibold))

                Text(agent.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Text("Prompt")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if didCopy {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }

                    Button {
                        copyPrompt()
                    } label: {
                        Label("Copy Prompt", systemImage: "doc.on.doc")
                    }
                }

                Text(agent.prompt)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: agent.id) {
            didCopy = false
        }
    }

    private func copyPrompt() {
        PromptPasteboard.copy(agent)
        withAnimation { didCopy = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { didCopy = false }
        }
    }
}

#Preview {
    AgentDetailView(agent: SeedAgents.implementer)
        .frame(width: 320, height: 360)
}
