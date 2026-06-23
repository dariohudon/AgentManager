import Foundation

/// User-managed dropdown options for the Agent Library: extra categories the
/// user has added, and the list of Preferred AI / tool choices.
///
/// Categories shown in the editor are derived from existing agents' categories
/// unioned with `categories`; this struct only needs to remember the *custom*
/// categories the user typed that no agent uses yet. Preferred AI choices are
/// stored in full (seeded with the defaults) so order is preserved.
struct LibraryOptions: Codable, Equatable, Sendable {
    var categories: [String]
    var preferredAIs: [String]

    /// Default Preferred AI / tool options.
    static let defaultPreferredAIs = ["ChatGPT", "Claude", "Perplexity", "Zapier", "Descript"]

    /// Initial options written on first run: no custom categories yet, and the
    /// default Preferred AI list.
    static let initial = LibraryOptions(categories: [], preferredAIs: defaultPreferredAIs)
}
