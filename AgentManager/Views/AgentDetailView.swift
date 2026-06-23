import SwiftUI

/// Inspection view for the selected agent: a calm header (name + a single
/// metadata line + optional purpose), a clear primary action, and the prompt
/// as the focus of the page.
///
/// Visual hierarchy (M03-S03): **Copy Prompt** is the prominent primary action;
/// Edit and Duplicate are quiet secondary icon buttons; Delete is tucked into a
/// "more" menu so it never competes with the primary/secondary actions. Copy
/// Prompt still copies only `agent.prompt`.
struct AgentDetailView: View {
    let agent: Agent
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var didCopy = false

    private var trimmedDescription: String {
        agent.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                actionBar

                Divider()

                Text("Instructions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(agent.prompt)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: agent.id) {
            didCopy = false
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(agent.title.isEmpty ? agent.name : agent.title)
                .font(.title2.weight(.semibold))

            Text("\(agent.category) • \(agent.preferredAI)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !trimmedDescription.isEmpty {
                Text(trimmedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Actions

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button(action: copyPrompt) {
                Label(didCopy ? "Copied" : "Copy Prompt",
                      systemImage: didCopy ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)

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
        .frame(width: 360, height: 400)
}
