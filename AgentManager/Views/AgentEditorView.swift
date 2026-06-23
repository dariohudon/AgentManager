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
/// Presented inline inside the Agent Library surface (not as a `.sheet`), which
/// is stable inside the `MenuBarExtra` popover and the hotkey window. Category
/// and Preferred AI are managed dropdowns: the menu lists existing choices and
/// an "Add…" toggle reveals a small field to add a new option.
struct AgentEditorView: View {
    let mode: AgentEditorMode
    let vault: AgentVault
    let onClose: () -> Void

    @State private var name = ""
    @State private var title = ""
    @State private var category = Agent.defaultCategory
    @State private var preferredAI = Agent.defaultPreferredAI
    @State private var description = ""
    @State private var prompt = ""

    @State private var isAddingCategory = false
    @State private var newCategory = ""
    @State private var isAddingPreferredAI = false
    @State private var newPreferredAI = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Agent" : "New Agent")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                categoryField

                preferredAIField

                TextField("Title", text: $title)
                TextField("Description", text: $description)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 110)
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

    // MARK: - Category

    @ViewBuilder
    private var categoryField: some View {
        Picker("Category", selection: $category) {
            ForEach(categoryOptions, id: \.self) { option in
                Text(option).tag(option)
            }
        }

        if isAddingCategory {
            HStack {
                TextField("New category", text: $newCategory)
                Button("Add") { commitNewCategory() }
                    .disabled(newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            Button("Add Category…") { isAddingCategory = true }
                .font(.caption)
        }
    }

    private var categoryOptions: [String] {
        var options = vault.categoryChoices
        if !options.contains(category) { options.append(category) }
        return options
    }

    private func commitNewCategory() {
        let trimmed = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vault.addCategoryOption(trimmed)
        category = trimmed
        newCategory = ""
        isAddingCategory = false
    }

    // MARK: - Preferred AI

    @ViewBuilder
    private var preferredAIField: some View {
        Picker("Preferred AI", selection: $preferredAI) {
            ForEach(preferredAIOptions, id: \.self) { option in
                Text(option).tag(option)
            }
        }

        if isAddingPreferredAI {
            HStack {
                TextField("New AI / tool", text: $newPreferredAI)
                Button("Add") { commitNewPreferredAI() }
                    .disabled(newPreferredAI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else {
            Button("Add Preferred AI…") { isAddingPreferredAI = true }
                .font(.caption)
        }
    }

    private var preferredAIOptions: [String] {
        var options = vault.preferredAIChoices
        if !options.contains(preferredAI) { options.append(preferredAI) }
        return options
    }

    private func commitNewPreferredAI() {
        let trimmed = newPreferredAI.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vault.addPreferredAIOption(trimmed)
        preferredAI = trimmed
        newPreferredAI = ""
        isAddingPreferredAI = false
    }

    // MARK: - Save

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// Name and prompt are required; the rest may be blank/defaulted.
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func populate() {
        if case .edit(let agent) = mode {
            name = agent.name
            title = agent.title
            category = agent.category
            preferredAI = agent.preferredAI
            description = agent.description
            prompt = agent.prompt
        }
    }

    private func save() {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = trimmedCategory.isEmpty ? Agent.defaultCategory : trimmedCategory
        let trimmedAI = preferredAI.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalAI = trimmedAI.isEmpty ? Agent.defaultPreferredAI : trimmedAI

        switch mode {
        case .add:
            vault.add(
                name: name,
                title: title,
                description: description,
                category: finalCategory,
                preferredAI: finalAI,
                prompt: prompt
            )
        case .edit(let agent):
            vault.update(
                id: agent.id,
                name: name,
                title: title,
                description: description,
                category: finalCategory,
                preferredAI: finalAI,
                prompt: prompt
            )
        }
        onClose()
    }
}

#Preview("Add") {
    AgentEditorView(mode: .add, vault: AgentVault(agents: []), onClose: {})
        .frame(width: 460, height: 520)
}

#Preview("Edit") {
    AgentEditorView(mode: .edit(SeedAgents.architect), vault: AgentVault(agents: SeedAgents.all), onClose: {})
        .frame(width: 460, height: 520)
}
