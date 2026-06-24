import AppKit
import SwiftUI

/// The Agent Manager panel shown when the menu bar item is clicked, and the
/// content of the hotkey-opened window.
///
/// Hosts the agent browser (list/detail) over a shared `AgentVault` backed by
/// local JSON persistence. Add/edit/delete and Copy Prompt live in the
/// browser/detail views. The vault is injected so the menu bar panel and the
/// global-shortcut window share one source of truth. Quit lives in Settings
/// (app-level), not in this content surface.
struct ContentView: View {
    let vault: AgentVault

    var body: some View {
        AgentBrowserView(vault: vault)
            // Wider surface (was 560): ~+20pt for the sidebar and ~+60pt
            // for the detail side, giving the inspector more breathing room.
            .frame(width: 640, height: 420)
            // Opaque native window background so the menu bar popover and hotkey
            // window read as a neutral content surface rather than letting the
            // app's accent/translucency bleed through.
            .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    ContentView(vault: AgentVault(agents: SeedAgents.all))
}
