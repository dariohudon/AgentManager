import Foundation

/// A reusable AI agent stored in the Agent Manager library.
///
/// The library model is Agent Library → Category → Agent → Instructions, so
/// each agent belongs to a `category`. The user-facing fields are `name`,
/// `title`, `description`, `category`, and `prompt` (the instructions).
/// `id`, `createdAt`, and `updatedAt` are bookkeeping fields used by
/// persistence and ordering.
struct Agent: Identifiable, Codable, Equatable, Sendable {
    /// Category assigned to agents that have none (including older JSON records
    /// saved before categories existed).
    static let defaultCategory = "General"

    let id: UUID
    let name: String
    let title: String
    let description: String
    let category: String
    let prompt: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        title: String,
        description: String,
        category: String = Agent.defaultCategory,
        prompt: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.category = category
        self.prompt = prompt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, title, description, category, prompt, createdAt, updatedAt
    }

    /// Custom decoding so JSON written before categories existed still loads:
    /// a missing `category` falls back to `defaultCategory`. Encoding stays
    /// synthesized and always writes `category`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
            ?? Agent.defaultCategory
        prompt = try container.decode(String.self, forKey: .prompt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
