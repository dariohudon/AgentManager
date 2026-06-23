import SwiftUI

/// Inline settings panel for app-level reusable options and app info.
///
/// Presented as an inline mode inside the Agent Library surface (not a
/// `.sheet`/popover), so it is stable in both the `MenuBarExtra` popover and
/// the hotkey window. Scope is deliberately narrow: it manages the shared
/// dropdown options (categories, Preferred AI) and shows storage/shortcut info.
/// Per-agent content lives in the agent editor/detail, never here.
struct SettingsView: View {
    let vault: AgentVault
    let onClose: () -> Void

    @State private var isAddingCategory = false
    @State private var newCategory = ""
    @State private var isAddingPreferredAI = false
    @State private var newPreferredAI = ""

    private static let agentsPath = "~/Library/Application Support/AgentManager/agents.json"
    private static let optionsPath = "~/Library/Application Support/AgentManager/options.json"
    private static let shortcut = "Control + Option + Space"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { onClose() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    optionSection(
                        title: "Categories",
                        addLabel: "Add Category…",
                        placeholder: "New category",
                        items: vault.categoryChoices,
                        isAdding: $isAddingCategory,
                        newValue: $newCategory,
                        add: { vault.addCategoryOption($0) }
                    )

                    optionSection(
                        title: "Preferred AI",
                        addLabel: "Add Preferred AI…",
                        placeholder: "New AI / tool",
                        items: vault.preferredAIChoices,
                        isAdding: $isAddingPreferredAI,
                        newValue: $newPreferredAI,
                        add: { vault.addPreferredAIOption($0) }
                    )

                    infoSection
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func optionSection(
        title: String,
        addLabel: String,
        placeholder: String,
        items: [String],
        isAdding: Binding<Bool>,
        newValue: Binding<String>,
        add: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.bold))

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if isAdding.wrappedValue {
                HStack {
                    TextField(placeholder, text: newValue)
                    Button("Add") {
                        add(newValue.wrappedValue)
                        newValue.wrappedValue = ""
                        isAdding.wrappedValue = false
                    }
                    .disabled(newValue.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                Button(addLabel) { isAdding.wrappedValue = true }
                    .font(.caption)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Info")
                .font(.title3.weight(.bold))

            infoRow(label: "Agents storage", value: Self.agentsPath)
            infoRow(label: "Options storage", value: Self.optionsPath)
            infoRow(label: "Shortcut", value: Self.shortcut)

            Text("The shortcut opens a standalone Agent Manager window, because the menu bar popover cannot be opened programmatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    SettingsView(vault: AgentVault(agents: SeedAgents.all), onClose: {})
        .frame(width: 560, height: 420)
}
