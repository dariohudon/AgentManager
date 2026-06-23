import AppKit
import SwiftUI

/// Manages a standalone Agent Manager window that hosts the same Agent Library
/// UI (`ContentView`) as the menu bar panel, backed by the shared `AgentVault`.
///
/// `MenuBarExtra` popovers can't be opened programmatically, so the global
/// hot key brings up this window instead. The window is created lazily and
/// reused; closing it just hides it (the app keeps running in the menu bar).
final class AgentManagerWindowController {
    private let vault: AgentVault
    private var window: NSWindow?

    init(vault: AgentVault) {
        self.vault = vault
    }

    /// Brings the Agent Library window forward, creating it on first use.
    func showWindow() {
        if window == nil {
            let hosting = NSHostingController(rootView: ContentView(vault: vault))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Agent Manager"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
    }
}
