import AppKit
import SwiftUI

/// Agent Manager runs as a macOS menu bar app (a status item in the system
/// menu bar). Clicking the menu bar item opens the Agent Library panel; a
/// global keyboard shortcut (Control + Option + Space) opens the library in a
/// standalone window — see `AppDelegate`.
///
/// Dock behavior: the app currently keeps its default Dock presence. Hiding the
/// Dock icon (`LSUIElement` / `.accessory` activation policy) to make this a
/// pure menu-bar-only app remains deferred to a later milestone.
@main
struct AgentManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Agent Manager", systemImage: "square.stack.3d.up") {
            ContentView(vault: appDelegate.vault)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the single shared `AgentVault` (used by both the menu bar panel and the
/// hotkey-opened window) and registers the global keyboard shortcut.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The single source of truth for agents, shared across surfaces.
    let vault = AgentVault()

    private var hotKey: GlobalHotKey?
    private lazy var windowController = AgentManagerWindowController(vault: vault)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Control + Option + Space opens the Agent Library window from anywhere
        // while Agent Manager is running.
        hotKey = GlobalHotKey.controlOptionSpace { [weak self] in
            self?.showLibrary()
        }
        if hotKey == nil {
            NSLog(
                "AgentManager: could not register the global shortcut "
                    + "(Control+Option+Space). It may already be in use by macOS "
                    + "(e.g. input-source switching) or another app."
            )
        }
    }

    private func showLibrary() {
        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow()
    }
}
