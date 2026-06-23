import AppKit
import SwiftUI

/// The Agent Manager panel shown when the menu bar item is clicked.
///
/// Hosts the agent browser (list/detail) over the seed agents from the
/// M01-S03 provider, with a Quit control in the footer. Copy-to-clipboard
/// (M01-S05), durable persistence (M01-S06), and the global shortcut (M01-S07)
/// are intentionally out of scope here.
struct ContentView: View {
    private let agents: [Agent] = ContentView.loadAgents()

    /// Loads agents from the local JSON store, falling back to the seed agents
    /// if the store location can't be resolved or read.
    private static func loadAgents() -> [Agent] {
        guard let store = AgentStore() else { return SeedAgents.all }
        return (try? store.load()) ?? SeedAgents.all
    }

    var body: some View {
        VStack(spacing: 0) {
            AgentBrowserView(agents: agents)
                .frame(width: 520, height: 360)

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
