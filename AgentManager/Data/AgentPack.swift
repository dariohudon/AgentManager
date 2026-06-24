import Foundation

// MARK: - Exchange format

/// Versioned, AI-friendly exchange format for sharing agents into and out of the
/// app. This is an **import/export format only** — local storage (`agents.json`)
/// is unchanged. An Agent Pack can carry one agent, one category, several
/// categories, or the whole library.
struct AgentPack: Codable, Equatable {
    /// The schema version this build writes and is able to import.
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var packType: String          // "library" | "categories" | "category" | "agent"
    var name: String?
    var description: String?
    var createdBy: String?
    var updatedAt: String?        // free-form ISO-8601 timestamp (informational)
    var importMode: String?       // "merge" (the only supported mode today)
    var categories: [String]?
    var agents: [PackAgent]
}

/// One agent inside an Agent Pack. `slug` is the stable identity (it maps to the
/// app's `Agent.name` handle); `purpose`/`instructions` map to the app's
/// `description`/`prompt`. Most fields are optional so packs stay forgiving, but
/// an entry needs an identity (slug or name) and instructions to be applicable.
struct PackAgent: Codable, Equatable {
    var slug: String?
    var name: String?
    var title: String?
    var category: String?
    var preferredAI: String?
    var purpose: String?
    var instructions: String?
}

// MARK: - Errors

enum AgentPackError: Error, LocalizedError, Equatable {
    case malformedJSON
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case empty

    var errorDescription: String? {
        switch self {
        case .malformedJSON:
            return "This isn't valid Agent Pack JSON."
        case let .unsupportedSchemaVersion(found, supported):
            return "Unsupported Agent Pack schemaVersion \(found). This app supports version \(supported)."
        case .empty:
            return "The Agent Pack contains no agents."
        }
    }
}

// MARK: - Import plan

/// The result of planning an import against the current library, without
/// applying anything. Drives the preview (counts + lists) and the apply step.
struct AgentImportPlan: Equatable {
    /// Brand-new agents (fresh id + timestamps) to append.
    var additions: [Agent] = []
    /// Existing agents to replace (same id + createdAt preserved, updatedAt bumped).
    var updates: [Agent] = []
    /// Display names of entries that matched an existing agent with no changes.
    var unchanged: [String] = []
    /// Human-readable reasons entries were rejected (not applied).
    var errors: [String] = []

    var addCount: Int { additions.count }
    var updateCount: Int { updates.count }
    var unchangedCount: Int { unchanged.count }
    var errorCount: Int { errors.count }

    /// Whether applying would change anything.
    var hasApplicableChanges: Bool { !additions.isEmpty || !updates.isEmpty }
}

// MARK: - Service

/// Pure decode / validate / plan / export logic for Agent Packs. No UI, no
/// persistence — `AgentVault.applyImport` performs the mutation.
enum AgentPackService {
    // MARK: Import

    /// Decodes Agent Pack JSON text. Throws `.malformedJSON` if it can't be parsed.
    static func decode(_ text: String) throws -> AgentPack {
        guard let data = text.data(using: .utf8) else { throw AgentPackError.malformedJSON }
        do {
            return try JSONDecoder().decode(AgentPack.self, from: data)
        } catch {
            throw AgentPackError.malformedJSON
        }
    }

    /// Validates a decoded pack. Throws on unsupported schema version or empty pack.
    static func validate(_ pack: AgentPack) throws {
        guard pack.schemaVersion == AgentPack.currentSchemaVersion else {
            throw AgentPackError.unsupportedSchemaVersion(
                found: pack.schemaVersion,
                supported: AgentPack.currentSchemaVersion
            )
        }
        guard !pack.agents.isEmpty else { throw AgentPackError.empty }
    }

    /// Builds an import plan against the current agents. Matching uses the stable
    /// identity `slug ?? name` against the existing `Agent.name` (case-insensitive).
    /// Nothing is mutated.
    static func plan(pack: AgentPack, existing: [Agent], now: Date) -> AgentImportPlan {
        var plan = AgentImportPlan()
        let existingByKey = Dictionary(
            existing.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for entry in pack.agents {
            let identity = trimmed(entry.slug) ?? trimmed(entry.name)
            guard let identity, !identity.isEmpty else {
                plan.errors.append("Skipped an agent with no slug or name.")
                continue
            }
            guard let instructions = trimmed(entry.instructions), !instructions.isEmpty else {
                plan.errors.append("Skipped \"\(identity)\": missing instructions.")
                continue
            }

            let name = identity
            let title = trimmed(entry.title) ?? trimmed(entry.name) ?? identity
            let category = trimmed(entry.category) ?? Agent.defaultCategory
            let preferredAI = trimmed(entry.preferredAI) ?? Agent.defaultPreferredAI
            let purpose = entry.purpose ?? ""

            if let match = existingByKey[identity.lowercased()] {
                let updated = Agent(
                    id: match.id,
                    name: name,
                    title: title,
                    description: purpose,
                    category: category,
                    preferredAI: preferredAI,
                    prompt: instructions,
                    createdAt: match.createdAt,
                    updatedAt: now
                )
                if sameUserFacingFields(match, updated) {
                    plan.unchanged.append(name)
                } else {
                    plan.updates.append(updated)
                }
            } else {
                plan.additions.append(
                    Agent(
                        name: name,
                        title: title,
                        description: purpose,
                        category: category,
                        preferredAI: preferredAI,
                        prompt: instructions,
                        createdAt: now,
                        updatedAt: now
                    )
                )
            }
        }
        return plan
    }

    // MARK: Export

    static func makeLibraryPack(agents: [Agent], now: Date, createdBy: String? = nil) -> AgentPack {
        let categories = Set(agents.map(\.category)).sorted()
        return AgentPack(
            schemaVersion: AgentPack.currentSchemaVersion,
            packType: "library",
            name: "Agent Library",
            description: "Full Agent Manager library export.",
            createdBy: createdBy,
            updatedAt: iso8601(now),
            importMode: "merge",
            categories: categories,
            agents: agents.map(packAgent(from:))
        )
    }

    static func makeCategoryPack(agents: [Agent], category: String, now: Date) -> AgentPack {
        let inCategory = agents.filter { $0.category == category }
        return AgentPack(
            schemaVersion: AgentPack.currentSchemaVersion,
            packType: "category",
            name: category,
            description: "Agents in the \"\(category)\" category.",
            createdBy: nil,
            updatedAt: iso8601(now),
            importMode: "merge",
            categories: [category],
            agents: inCategory.map(packAgent(from:))
        )
    }

    static func makeAgentPack(_ agent: Agent, now: Date) -> AgentPack {
        AgentPack(
            schemaVersion: AgentPack.currentSchemaVersion,
            packType: "agent",
            name: agent.name,
            description: "Single agent export.",
            createdBy: nil,
            updatedAt: iso8601(now),
            importMode: "merge",
            categories: [agent.category],
            agents: [packAgent(from: agent)]
        )
    }

    /// Encodes a pack to pretty-printed JSON text.
    static func encode(_ pack: AgentPack) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(pack)
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Helpers

    private static func packAgent(from agent: Agent) -> PackAgent {
        PackAgent(
            slug: agent.name,
            name: agent.name,
            title: agent.title,
            category: agent.category,
            preferredAI: agent.preferredAI,
            purpose: agent.description,
            instructions: agent.prompt
        )
    }

    private static func sameUserFacingFields(_ lhs: Agent, _ rhs: Agent) -> Bool {
        lhs.name == rhs.name
            && lhs.title == rhs.title
            && lhs.description == rhs.description
            && lhs.category == rhs.category
            && lhs.preferredAI == rhs.preferredAI
            && lhs.prompt == rhs.prompt
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
