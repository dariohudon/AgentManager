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

/// Inline form for creating or editing an agent.
///
/// This is presented inline inside the Agent Library surface (not as a `.sheet`
/// or popover). Sheets attached to a `MenuBarExtra` popover are dismissed when
/// focus moves between fields or when the popover resigns key, which made the
/// editor disappear mid-edit. An inline editor stays put while the user tabs
/// between fields and is dismissed only via Save/Cancel.
struct AgentEditorView: View {
    let mode: AgentEditorMode
    let vault: AgentVault
    let onClose: () -> Void

    @State private var name = ""
    @State private var title = ""
    @State private var category = Agent.defaultCategory
    @State private var description = ""
    @State private var prompt = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Agent" : "New Agent")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                TextField("Category", text: $category)
                TextField("Title", text: $title)
                TextField("Description", text: $description)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.quaternary)
                        )
                }
            }
            .formStyle(.columns)

            HStack {
                Button("Cancel", role: .cancel) { onClose() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear(perform: populate)
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// Name and prompt are required; category, title, and description may be blank.
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func populate() {
        if case .edit(let agent) = mode {
            name = agent.name
            title = agent.title
            category = agent.category
            description = agent.description
            prompt = agent.prompt
        }
    }

    private func save() {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = trimmedCategory.isEmpty ? Agent.defaultCategory : trimmedCategory

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
        onClose()
    }
}

#Preview("Add") {
    AgentEditorView(mode: .add, vault: AgentVault(agents: []), onClose: {})
        .frame(width: 460, height: 440)
}

#Preview("Edit") {
    AgentEditorView(mode: .edit(SeedAgents.architect), vault: AgentVault(agents: SeedAgents.all), onClose: {})
        .frame(width: 460, height: 440)
}
