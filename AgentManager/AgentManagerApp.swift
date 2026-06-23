import SwiftUI

/// Agent Manager runs as a macOS menu bar app (a status item in the system
/// menu bar). Clicking the menu bar item opens the Agent Manager panel.
///
/// Dock behavior (M01-S02 decision): the app currently keeps its default Dock
/// presence — it still appears in the Dock and as a regular app. Hiding the
/// Dock icon (e.g. via `LSUIElement` / `.accessory` activation policy) to make
/// this a pure menu-bar-only app is intentionally deferred to a later card so
/// M01-S02 stays a minimal shell.
@main
struct AgentManagerApp: App {
    var body: some Scene {
        MenuBarExtra("Agent Manager", systemImage: "square.stack.3d.up") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
