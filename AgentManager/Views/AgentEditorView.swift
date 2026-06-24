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
/// and Preferred AI are chosen from dropdowns; managing the available options
/// lives in Settings (app-level), not here.
///
/// Draft edits live in `@State` and are committed only on Save — so the user
/// can leave Agent Manager to copy text and return (in the standalone hotkey
/// window, which persists across app switches) without losing in-progress
/// edits; Cancel intentionally discards them. There is no editable Title field:
/// `Name` is the single identity field, and `title` is synced from `name` on
/// save (the stored model keeps `title` for compatibility).
struct AgentEditorView: View {
    let mode: AgentEditorMode
    let vault: AgentVault
    let onClose: () -> Void

    @State private var name = ""
    @State private var category = Agent.defaultCategory
    @State private var preferredAI = Agent.defaultPreferredAI
    @State private var purpose = ""
    @State private var instructions = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit Agent" : "New Agent")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(categoryOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Picker("Preferred AI", selection: $preferredAI) {
                    ForEach(preferredAIOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Text("Manage categories and AI options in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Purpose", text: $purpose)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $instructions)
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

    /// Category choices plus the current value (so editing an agent whose
    /// category isn't in the option list still shows it selected).
    private var categoryOptions: [String] {
        var options = vault.categoryChoices
        if !options.contains(category) { options.append(category) }
        return options
    }

    private var preferredAIOptions: [String] {
        var options = vault.preferredAIChoices
        if !options.contains(preferredAI) { options.append(preferredAI) }
        return options
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    /// Name and instructions are required; the rest may be blank/defaulted.
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func populate() {
        if case .edit(let agent) = mode {
            name = agent.name
            category = agent.category
            preferredAI = agent.preferredAI
            purpose = agent.description
            instructions = agent.prompt
        }
    }

    private func save() {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = trimmedCategory.isEmpty ? Agent.defaultCategory : trimmedCategory
        let trimmedAI = preferredAI.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalAI = trimmedAI.isEmpty ? Agent.defaultPreferredAI : trimmedAI
        // Title is no longer user-editable; keep the stored `title` in sync with
        // `name` so the model stays compatible without a redundant field.
        let syncedTitle = name

        switch mode {
        case .add:
            vault.add(
                name: name,
                title: syncedTitle,
                description: purpose,
                category: finalCategory,
                preferredAI: finalAI,
                prompt: instructions
            )
        case .edit(let agent):
            vault.update(
                id: agent.id,
                name: name,
                title: syncedTitle,
                description: purpose,
                category: finalCategory,
                preferredAI: finalAI,
                prompt: instructions
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
