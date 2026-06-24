import AppKit
import SwiftUI

/// Agent Manager runs as a macOS menu bar app (a status item in the system menu
/// bar). The status item and the global keyboard shortcut (Control + Option +
/// Space) both open the *same* single Agent Library window — see `AppDelegate`.
/// There is no separate anchored popover surface: a previous `MenuBarExtra`
/// `.window` style opened its own misplaced window on click, so the menu bar
/// icon is now an AppKit `NSStatusItem` that routes clicks through the shared
/// `AgentManagerWindowController`, exactly like the hotkey.
///
/// The SwiftUI `App` therefore has no standard window scene; the (empty)
/// `Settings` scene only satisfies SwiftUI's `Scene` requirement. The library
/// window itself is an AppKit `NSWindow` hosting the shared `ContentView`.
///
/// Dock behavior: the app currently keeps its default Dock presence. Hiding the
/// Dock icon (`LSUIElement` / `.accessory` activation policy) to make this a
/// pure menu-bar-only app remains deferred to a later milestone.
@main
struct AgentManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No main window scene: the Agent Library lives in the single reused
        // NSWindow managed by AppDelegate. This empty Settings scene exists only
        // to satisfy the `Scene` requirement without creating a second surface.
        Settings {
            EmptyView()
        }
    }
}

/// Owns the single shared `AgentVault` and the one Agent Library window, and
/// wires both the menu bar status item and the global keyboard shortcut to that
/// same window so there is only ever one app surface.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The single source of truth for agents, shared across surfaces.
    let vault = AgentVault()

    private var hotKey: GlobalHotKey?
    private var statusItem: NSStatusItem?
    private lazy var windowController = AgentManagerWindowController(vault: vault)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        // Control + Option + Space toggles the Agent Library window from
        // anywhere: brings it forward when hidden, orders it away when it is
        // already up front.
        hotKey = GlobalHotKey.controlOptionSpace { [weak self] in
            self?.windowController.toggle()
        }
        if hotKey == nil {
            NSLog(
                "AgentManager: could not register the global shortcut "
                    + "(Control+Option+Space). It may already be in use by macOS "
                    + "(e.g. input-source switching) or another app."
            )
        }
    }

    /// Installs the menu bar status item using the `MenuBarIcon` template asset.
    /// Clicking it toggles the same single Agent Library window the global
    /// shortcut uses, so the menu bar and the hotkey share one window — there is
    /// no separate anchored popover.
    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(named: "MenuBarIcon")
            // Template rendering lets macOS tint the icon for light/dark menu
            // bars and selection automatically (the asset is also marked as a
            // template, but set it explicitly to be safe).
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Agent Manager"
            button.target = self
            button.action = #selector(toggleWindow)
        }
        statusItem = item
    }

    /// Status item click handler: toggles the shared Agent Library window.
    @objc private func toggleWindow() {
        windowController.toggle()
    }
}
