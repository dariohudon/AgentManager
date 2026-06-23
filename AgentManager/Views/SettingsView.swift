import SwiftUI

/// Inline settings panel for app-level reusable options and app info.
///
/// Presented as an inline mode inside the Agent Library surface (not a
/// `.sheet`/popover), so it is stable in both the `MenuBarExtra` popover and
/// the hotkey window. Scope is deliberately narrow: it manages the shared
/// dropdown options (categories, Preferred AI) and shows storage/shortcut info
/// in a quiet App Info section. Per-agent content lives in the agent
/// editor/detail, never here.
struct SettingsView: View {
    let vault: AgentVault
    let onClose: () -> Void

    @State private var newCategory = ""
    @State private var newPreferredAI = ""

    private static let agentsPath = "~/Library/Application Support/AgentManager/agents.json"
    private static let optionsPath = "~/Library/Application Support/AgentManager/options.json"
    private static let shortcut = "Control + Option + Space"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { onClose() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)

            Divider()

            Form {
                Section("Categories") {
                    ForEach(vault.categoryChoices, id: \.self) { category in
                        Text(category)
                    }
                    addRow(placeholder: "Add category", text: $newCategory) {
                        vault.addCategoryOption(newCategory)
                        newCategory = ""
                    }
                }

                Section("Preferred AI") {
                    ForEach(vault.preferredAIChoices, id: \.self) { option in
                        Text(option)
                    }
                    addRow(placeholder: "Add AI / tool", text: $newPreferredAI) {
                        vault.addPreferredAIOption(newPreferredAI)
                        newPreferredAI = ""
                    }
                }

                Section("App Info") {
                    LabeledContent("Agents", value: Self.agentsPath)
                    LabeledContent("Options", value: Self.optionsPath)
                    LabeledContent("Shortcut", value: Self.shortcut)
                    Text("The shortcut opens a standalone window because the menu bar popover can't be opened programmatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
    }

    @ViewBuilder
    private func addRow(
        placeholder: String,
        text: Binding<String>,
        add: @escaping () -> Void
    ) -> some View {
        HStack {
            TextField(placeholder, text: text)
            Button("Add", action: add)
                .disabled(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

#Preview {
    SettingsView(vault: AgentVault(agents: SeedAgents.all), onClose: {})
        .frame(width: 560, height: 420)
}
