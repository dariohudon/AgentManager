import SwiftUI

/// Detail for the selected agent: title, description, and the full prompt.
/// The prompt sits in a scrollable region so long text stays readable. Actions
/// let the user copy the prompt, edit the agent, or delete it.
struct AgentDetailView: View {
    let agent: Agent
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var didCopy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(agent.title)
                        .font(.title2.weight(.semibold))

                    Spacer()

                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                }

                HStack(spacing: 6) {
                    Text(agent.category)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())

                    Label(agent.preferredAI, systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }

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
    AgentDetailView(agent: SeedAgents.implementer, onEdit: {}, onDelete: {})
        .frame(width: 340, height: 360)
}
