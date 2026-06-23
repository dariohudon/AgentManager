import Foundation

/// A reusable AI agent stored in the Agent Manager vault.
///
/// The four user-facing fields are `name`, `title`, `description`, and
/// `prompt`. `id`, `createdAt`, and `updatedAt` are bookkeeping fields used by
/// persistence and ordering (durable storage arrives in M01-S06).
struct Agent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let title: String
    let description: String
    let prompt: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        title: String,
        description: String,
        prompt: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.prompt = prompt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
