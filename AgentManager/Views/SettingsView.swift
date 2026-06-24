import AppKit
import SwiftUI

/// Inline settings panel for app-level reusable options, Agent Pack
/// import/export, app info, and Quit.
///
/// Presented as an inline mode inside the Agent Library surface (not a
/// `.sheet`/popover), so it is stable in both the `MenuBarExtra` popover and
/// the hotkey window. Scope is app-level: shared dropdown options (with
/// rename/delete), the import/export exchange surface, storage/shortcut info,
/// and Quit. Per-agent content lives in the agent editor/detail, never here.
struct SettingsView: View {
    let vault: AgentVault
    let onClose: () -> Void

    @State private var newCategory = ""
    @State private var newPreferredAI = ""

    // Category rename state.
    @State private var renamingCategory: String?
    @State private var renameText = ""

    // Agent Pack import/export state.
    @State private var importText = ""
    @State private var importPlan: AgentImportPlan?
    @State private var importError: String?
    @State private var importResult: String?
    @State private var exportStatus: String?

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
                        categoryRow(category)
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

                agentPacksSection

                Section("App Info") {
                    LabeledContent("Agents", value: Self.agentsPath)
                    LabeledContent("Options", value: Self.optionsPath)
                    LabeledContent("Shortcut", value: Self.shortcut)
                    Text("The shortcut opens the window when hidden and orders it away when it's up front. It uses a standalone window because the menu bar popover can't be opened programmatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Quit Agent Manager") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q")
                }
            }
            .formStyle(.grouped)
        }
    }

    // MARK: - Categories

    @ViewBuilder
    private func categoryRow(_ category: String) -> some View {
        if renamingCategory == category {
            HStack {
                TextField("Rename category", text: $renameText)
                Button("Save") { commitRename(from: category) }
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) { cancelRename() }
            }
        } else {
            HStack {
                Text(category)
                Spacer()
                Menu {
                    Button("Rename…") { startRename(category) }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        vault.deleteCategory(category)
                    }
                    .disabled(category == Agent.defaultCategory)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private func startRename(_ category: String) {
        renamingCategory = category
        renameText = category
    }

    private func commitRename(from old: String) {
        vault.renameCategory(old, to: renameText)
        cancelRename()
    }

    private func cancelRename() {
        renamingCategory = nil
        renameText = ""
    }

    // MARK: - Agent Packs

    @ViewBuilder
    private var agentPacksSection: some View {
        Section("Agent Packs") {
            // Export
            VStack(alignment: .leading, spacing: 4) {
                Button("Copy Library as Agent Pack", action: exportLibrary)
                if let exportStatus {
                    Text(exportStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Import: Preview/results sit ABOVE the JSON field so the user
            // doesn't need to scroll past the text editor after pasting.
            VStack(alignment: .leading, spacing: 6) {
                Text("Import Agent Pack JSON")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let plan = importPlan {
                    importPreview(plan)
                } else {
                    Button("Preview Import", action: previewImport)
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let importError {
                    Text(importError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let importResult {
                    Text(importResult)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                TextEditor(text: $importText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
            }
        }
    }

    @ViewBuilder
    private func importPreview(_ plan: AgentImportPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Preview: \(plan.addCount) to add · \(plan.updateCount) to update · \(plan.unchangedCount) unchanged · \(plan.errorCount) errors")
                .font(.caption)

            ForEach(plan.errors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancel", role: .cancel) { resetImport() }
                Spacer()
                Button("Apply") { applyImport(plan) }
                    .disabled(!plan.hasApplicableChanges)
            }
            .padding(.top, 2)
        }
    }

    private func exportLibrary() {
        importResult = nil
        do {
            let pack = AgentPackService.makeLibraryPack(agents: vault.agents, now: Date())
            let json = try AgentPackService.encode(pack)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(json, forType: .string)
            exportStatus = "Library copied to clipboard (\(vault.agents.count) agents)."
        } catch {
            exportStatus = "Export failed."
        }
    }

    private func previewImport() {
        importError = nil
        importResult = nil
        do {
            let pack = try AgentPackService.decode(importText)
            try AgentPackService.validate(pack)
            importPlan = AgentPackService.plan(pack: pack, existing: vault.agents, now: Date())
        } catch {
            importPlan = nil
            importError = error.localizedDescription
        }
    }

    private func applyImport(_ plan: AgentImportPlan) {
        vault.applyImport(plan)
        importResult = "Imported: \(plan.addCount) added, \(plan.updateCount) updated."
        importText = ""
        importPlan = nil
        importError = nil
    }

    private func resetImport() {
        importPlan = nil
        importError = nil
    }

    // MARK: - Options add row

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
