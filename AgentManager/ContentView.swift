import AppKit
import SwiftUI

/// The Agent Manager panel shown when the menu bar item is clicked.
///
/// Hosts the agent browser (list/detail) over an `AgentVault` backed by local
/// JSON persistence, with a Quit control in the footer. Add/edit/delete and
/// Copy Prompt live in the browser/detail views. The global summon shortcut is
/// M01-S08.
struct ContentView: View {
    @State private var vault = AgentVault()

    var body: some View {
        VStack(spacing: 0) {
            AgentBrowserView(vault: vault)
                .frame(width: 560, height: 420)

            Divider()

            HStack {
                Spacer()
                Button("Quit Agent Manager") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ContentView()
}
