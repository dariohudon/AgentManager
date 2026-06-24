import AppKit
import SwiftUI

/// Manages a standalone Agent Manager window that hosts the same Agent Library
/// UI (`ContentView`) as the menu bar panel, backed by the shared `AgentVault`.
///
/// `MenuBarExtra` popovers can't be opened programmatically, so the global
/// hot key brings up this window instead. The window is created lazily and
/// **reused** — closing it just hides it (the app keeps running in the menu
/// bar). Reuse is what makes editing reliable: the hosted SwiftUI view (and its
/// in-progress editor `@State` draft) is created once and survives the user
/// switching to another app to copy text and back. The window also does not
/// hide when the app deactivates, so it stays visible for that copy/paste flow.
/// This is the reliable editing surface; the menu bar popover dismisses on
/// focus loss, which is native behavior we don't fight.
final class AgentManagerWindowController {
    private let vault: AgentVault
    private var window: NSWindow?

    init(vault: AgentVault) {
        self.vault = vault
    }

    /// Brings the Agent Library window forward, creating it on first use and
    /// reusing it thereafter (so in-progress edits are never torn down), and
    /// activates the app.
    func showWindow() {
        if window == nil {
            let hosting = NSHostingController(rootView: ContentView(vault: vault))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Agent Manager"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            // Stay visible when the user switches to another app to copy/paste
            // while editing, so unsaved draft edits are never lost to focus
            // changes.
            window.hidesOnDeactivate = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Global-shortcut behavior: if the window is up front (visible and key),
    /// order it away; otherwise bring it forward. Hiding via `orderOut` keeps
    /// the reused window (and its in-progress editor state) alive, so toggling
    /// away and back does not break the edit workflow.
    func toggle() {
        if let window, window.isVisible, window.isKeyWindow {
            window.orderOut(nil)
        } else {
            showWindow()
        }
    }
}
