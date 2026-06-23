import Foundation

/// Local JSON persistence for the agent vault.
///
/// Agents are stored as a single JSON array at
/// `~/Library/Application Support/AgentManager/agents.json`. On first run (no
/// file yet) the built-in seed agents are written to disk and returned;
/// subsequent runs decode and return the saved agents, so changes survive an
/// app restart.
///
/// The store URL is injectable so tests (and previews) can use a temporary
/// directory instead of the real Application Support location.
struct AgentStore {
    private let fileManager: FileManager

    /// The on-disk location of the agent vault JSON file.
    let storeURL: URL

    /// Creates a store at the default Application Support location. Returns nil
    /// only if that location cannot be resolved.
    init?(fileManager: FileManager = .default) {
        guard let url = Self.defaultStoreURL(fileManager: fileManager) else {
            return nil
        }
        self.fileManager = fileManager
        self.storeURL = url
    }

    /// Creates a store at an explicit location (used by tests and previews).
    init(storeURL: URL, fileManager: FileManager = .default) {
        self.storeURL = storeURL
        self.fileManager = fileManager
    }

    /// Whether the local JSON file already exists.
    var hasLocalData: Bool {
        fileManager.fileExists(atPath: storeURL.path)
    }

    /// Loads agents from disk. On first run (no file yet) the seed agents are
    /// written to disk and returned.
    func load() throws -> [Agent] {
        guard hasLocalData else {
            let seed = SeedAgents.all
            try save(seed)
            return seed
        }
        let data = try Data(contentsOf: storeURL)
        return try Self.decoder.decode([Agent].self, from: data)
    }

    /// Saves agents to disk as JSON, creating the parent directory if needed.
    /// The write is atomic so a partial write cannot corrupt the vault.
    func save(_ agents: [Agent]) throws {
        let directory = storeURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(agents)
        try data.write(to: storeURL, options: .atomic)
    }

    /// The default on-disk location for the vault:
    /// `~/Library/Application Support/AgentManager/agents.json`.
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

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
