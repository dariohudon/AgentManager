import Foundation

extension String {
    /// The trimmed value suitable for display, or `nil` when the string is
    /// effectively empty: whitespace-only, or a dash-only placeholder such as
    /// "-", "--", "—", or "–". Used to keep placeholder clutter out of the UI
    /// (sidebar rows, Purpose, Instructions) without mutating stored data.
    var sanitizedForDisplay: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let isDashOnly = trimmed.allSatisfy { $0 == "-" || $0 == "—" || $0 == "–" }
        return isDashOnly ? nil : trimmed
    }
}
