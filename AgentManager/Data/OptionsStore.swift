import Foundation

/// Local JSON persistence for `LibraryOptions` (managed dropdown options),
/// stored alongside the agents at
/// `~/Library/Application Support/AgentManager/options.json`.
///
/// Kept separate from `agents.json` so the agent file format stays a plain
/// `[Agent]` array (backward-compatible). On first run (no file) the default
/// options are written and returned. The store URL is injectable for tests.
struct OptionsStore {
    private let fileManager: FileManager

    /// The on-disk location of the options JSON file.
    let storeURL: URL

    init?(fileManager: FileManager = .default) {
        guard let url = Self.defaultStoreURL(fileManager: fileManager) else {
            return nil
        }
        self.fileManager = fileManager
        self.storeURL = url
    }

    init(storeURL: URL, fileManager: FileManager = .default) {
        self.storeURL = storeURL
        self.fileManager = fileManager
    }

    var hasLocalData: Bool {
        fileManager.fileExists(atPath: storeURL.path)
    }

    /// Loads options from disk, writing and returning the defaults on first run.
    func load() throws -> LibraryOptions {
        guard hasLocalData else {
            try save(.initial)
            return .initial
        }
        let data = try Data(contentsOf: storeURL)
        return try Self.decoder.decode(LibraryOptions.self, from: data)
    }

    /// Saves options to disk as JSON, creating the parent directory if needed.
    /// The write is atomic.
    func save(_ options: LibraryOptions) throws {
        let directory = storeURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(options)
        try data.write(to: storeURL, options: .atomic)
    }

    /// `~/Library/Application Support/AgentManager/options.json`.
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
            .appendingPathComponent("options.json", isDirectory: false)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()
}
