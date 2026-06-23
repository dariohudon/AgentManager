import SwiftUI

/// Whether the editor is creating a new agent or editing an existing one.
enum AgentEditorMode: Identifiable {
    case add
    case edit(Agent)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let agent): agent.id.uuidString
        }
    }
}

/// Form for creating or editing an agent, presented as a sheet.
struct AgentEditorView: View {
    let mode: AgentEditorMode
    let vault: AgentVault

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var title = ""
    @State private var description = ""
    @State private var category = Agent.defaultCategory
    @State private var prompt = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Agent" : "New Agent")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                TextField("Title", text: $title)
                TextField("Category", text: $category)
                TextField("Description", text: $description)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.quaternary)
                        )
                }
            }
            .formStyle(.columns)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
        }
        .padding(16)
        .frame(width: 460, height: 440)
        .onAppear(perform: populate)
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// Name and prompt are required; title and description may be blank.
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func populate() {
        if case .edit(let agent) = mode {
            name = agent.name
            title = agent.title
            description = agent.description
            category = agent.category
            prompt = agent.prompt
        }
    }

    private func save() {
        let resolvedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = resolvedCategory.isEmpty ? Agent.defaultCategory : resolvedCategory

        switch mode {
        case .add:
            vault.add(
                name: name,
                title: title,
                description: description,
                category: finalCategory,
                prompt: prompt
            )
        case .edit(let agent):
            vault.update(
                id: agent.id,
                name: name,
                title: title,
                description: description,
                category: finalCategory,
                prompt: prompt
            )
        }
        dismiss()
    }
}

#Preview("Add") {
    AgentEditorView(mode: .add, vault: AgentVault(agents: []))
}

#Preview("Edit") {
    AgentEditorView(mode: .edit(SeedAgents.architect), vault: AgentVault(agents: SeedAgents.all))
}
