import SwiftUI

/// Inspection view for the selected agent — a calm, native capability page.
///
/// Layout (M03-S05): a clear name header with a compact `Category • Preferred AI`
/// metadata line; a compact toolbar (prominent Copy Prompt + secondary Edit /
/// Duplicate, with Delete tucked into a "more" menu); an optional **Purpose**
/// section (the agent's description, shown only when present); and the
/// **Instructions** area as the star — a prominent, scrollable card that fills
/// the remaining space.
///
/// Copy Prompt still copies only `agent.prompt`.
struct AgentDetailView: View {
    let agent: Agent
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            actionBar

            if let purpose = agent.description.sanitizedForDisplay {
                purposeSection(purpose)
            }

            instructionsSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: agent.id) {
            didCopy = false
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(agent.title.sanitizedForDisplay ?? agent.name)
                .font(.title2.weight(.semibold))

            Text("\(agent.category) • \(agent.preferredAI)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button(action: copyPrompt) {
                    Label(didCopy ? "Copied" : "Run / Copy",
                          systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .help("Copies the instructions to the clipboard. Preferred AI will guide future run/open actions.")

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .help("Edit agent")

                Button(action: onDuplicate) {
                    Image(systemName: "plus.square.on.square")
                }
                .help("Duplicate agent")

                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("More actions")
            }

            // Honest about today's behavior while signalling the future direction.
            Text("Copies the instructions for now. Preferred AI (\(agent.preferredAI)) will guide future run/open actions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Purpose

    private func purposeSection(_ purpose: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Purpose")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(purpose)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Instructions (the star)

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Instructions")
                .font(.headline)

            ScrollView {
                Group {
                    if agent.prompt.sanitizedForDisplay != nil {
                        Text(agent.prompt)
                            .font(.body)
                            .textSelection(.enabled)
                    } else {
                        Text("No instructions yet.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
    AgentDetailView(agent: SeedAgents.implementer, onEdit: {}, onDuplicate: {}, onDelete: {})
        .frame(width: 360, height: 420)
}
