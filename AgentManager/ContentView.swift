import AppKit
import SwiftUI

/// The Agent Manager panel shown when the menu bar item is clicked.
///
/// M01-S02 establishes only the menu bar shell. The agent list, detail view,
/// copy-prompt action, and local persistence arrive in later M01 cards, so this
/// is intentionally a small placeholder with a working Quit control.
struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agent Manager")
                .font(.headline)

            Text("Your reusable AI agents will live here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit Agent Manager") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
