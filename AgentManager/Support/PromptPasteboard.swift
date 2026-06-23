import AppKit

/// Copies an agent's prompt — and only the prompt — to the macOS clipboard.
///
/// The copy text is deliberately just `agent.prompt`: no title, name,
/// description, metadata, or surrounding formatting. `copyText(for:)` is kept
/// pure so it can be unit-tested without touching the system pasteboard.
enum PromptPasteboard {
    /// The exact text copied for an agent. Only the prompt is included.
    static func copyText(for agent: Agent) -> String {
        agent.prompt
    }

    /// Writes the agent's prompt to the given pasteboard (the shared system
    /// clipboard by default) and returns the text that was written.
    @discardableResult
    static func copy(_ agent: Agent, to pasteboard: NSPasteboard = .general) -> String {
        let text = copyText(for: agent)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        return text
    }
}
