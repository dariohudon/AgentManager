import Foundation

/// Minimal, read-only provider that supplies the agents the app should show.
///
/// M01-S03 scope: when no local agent data file exists, the built-in seed
/// agents are returned. Durable JSON load/save (reading and writing the local
/// data file) is intentionally deferred to M01-S06; this type only decides
/// whether a local file is present and otherwise falls back to the seed.
struct AgentProvider {
    private let fileManager: FileManager
    private let storeURL: URL?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.storeURL = Self.defaultStoreURL(fileManager: fileManager)
    }

    /// The agents to display. Returns the seed agents when no local data file
    /// exists yet.
    func loadAgents() -> [Agent] {
        SeedAgents.all
    }

    /// Whether a local agent data file already exists on disk. Used to decide
    /// between seeding and (in M01-S06) loading persisted data.
    var hasLocalData: Bool {
        guard let storeURL else { return false }
        return fileManager.fileExists(atPath: storeURL.path)
    }

    /// Planned on-disk location for the agent vault:
    /// `~/Library/Application Support/AgentManager/agents.json`.
    /// Computed here so persistence (M01-S06) has a single source of truth.
    static func defaultStoreURL(fileManager: FileManager = .default) -> URL? {
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return nil
        }
        return support
            .appendingPathComponent("AgentManager", isDirectory: true)
            .appendingPathComponent("agents.json", isDirectory: false)
    }
}
