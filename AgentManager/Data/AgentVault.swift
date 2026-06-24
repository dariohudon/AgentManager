import Foundation
import Observation

/// Observable, in-memory collection of agents backed by `AgentStore`, plus the
/// user-managed dropdown options backed by `OptionsStore`.
///
/// The vault loads agents and options on creation and persists every
/// add/edit/delete (and any newly added dropdown option), so changes survive an
/// app restart. Mutations follow value semantics — an edit replaces an `Agent`
/// with a new value rather than mutating it in place.
@Observable
final class AgentVault {
    private(set) var agents: [Agent]
    private(set) var options: LibraryOptions

    private let store: AgentStore?
    private let optionsStore: OptionsStore?

    /// Loads agents and options from the given stores (the default Application
    /// Support stores when omitted), falling back to the seed agents / default
    /// options if a store can't be resolved or read.
    init(store: AgentStore? = AgentStore(), optionsStore: OptionsStore? = OptionsStore()) {
        self.store = store
        self.optionsStore = optionsStore
        self.agents = store.flatMap { try? $0.load() } ?? SeedAgents.all
        self.options = optionsStore.flatMap { try? $0.load() } ?? .initial
    }

    /// In-memory vault with explicit agents/options and no persistence. Intended
    /// for previews and tests of empty/seed states.
    init(
        agents: [Agent],
        options: LibraryOptions = .initial,
        store: AgentStore? = nil,
        optionsStore: OptionsStore? = nil
    ) {
        self.store = store
        self.optionsStore = optionsStore
        self.agents = agents
        self.options = options
    }

    // MARK: - Dropdown choices

    /// Category choices for the editor: every category currently in use, plus
    /// any custom categories the user added, plus the default category. Sorted.
    var categoryChoices: [String] {
        var set = Set(agents.map(\.category))
        set.formUnion(options.categories)
        set.insert(Agent.defaultCategory)
        return set.sorted()
    }

    /// Preferred AI choices for the editor: the stored list, guaranteed to
    /// include all the built-in defaults (defaults first, then any custom).
    var preferredAIChoices: [String] {
        var result = options.preferredAIs
        for ai in LibraryOptions.defaultPreferredAIs where !result.contains(ai) {
            result.append(ai)
        }
        return result
    }

    /// Adds a custom category option (if non-empty and new) and persists.
    func addCategoryOption(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categoryChoices.contains(trimmed) else { return }
        options.categories.append(trimmed)
        persistOptions()
    }

    /// Adds a custom Preferred AI option (if non-empty and new) and persists.
    func addPreferredAIOption(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !preferredAIChoices.contains(trimmed) else { return }
        options.preferredAIs.append(trimmed)
        persistOptions()
    }

    // MARK: - Agent CRUD

    /// Adds a new agent and persists. Returns the created agent.
    @discardableResult
    func add(
        name: String,
        title: String,
        description: String,
        category: String,
        preferredAI: String,
        prompt: String,
        now: Date = Date()
    ) -> Agent {
        let agent = Agent(
            name: name,
            title: title,
            description: description,
            category: category,
            preferredAI: preferredAI,
            prompt: prompt,
            createdAt: now,
            updatedAt: now
        )
        agents.append(agent)
        persist()
        return agent
    }

    /// Replaces the agent with the given id, preserving its `id` and
    /// `createdAt` while bumping `updatedAt`. No-op if the id is unknown.
    func update(
        id: Agent.ID,
        name: String,
        title: String,
        description: String,
        category: String,
        preferredAI: String,
        prompt: String,
        now: Date = Date()
    ) {
        guard let index = agents.firstIndex(where: { $0.id == id }) else { return }
        let existing = agents[index]
        agents[index] = Agent(
            id: existing.id,
            name: name,
            title: title,
            description: description,
            category: category,
            preferredAI: preferredAI,
            prompt: prompt,
            createdAt: existing.createdAt,
            updatedAt: now
        )
        persist()
    }

    /// Duplicates the agent with the given id: a new `Agent` with a fresh `id`
    /// and timestamps, a name marked as a copy, and every other field
    /// (category, preferredAI, title, description, prompt) preserved. Persists
    /// and returns the duplicate, or nil if the id is unknown.
    @discardableResult
    func duplicate(id: Agent.ID, now: Date = Date()) -> Agent? {
        guard let original = agents.first(where: { $0.id == id }) else { return nil }
        let copy = Agent(
            name: "\(original.name) Copy",
            title: original.title,
            description: original.description,
            category: original.category,
            preferredAI: original.preferredAI,
            prompt: original.prompt,
            createdAt: now,
            updatedAt: now
        )
        agents.append(copy)
        persist()
        return copy
    }

    /// Deletes the agent with the given id and persists.
    func delete(id: Agent.ID) {
        agents.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Agent Pack import

    /// Applies a planned Agent Pack import: appends additions and replaces
    /// matched agents with their updates, then persists once. Unchanged entries
    /// and errors in the plan are ignored (nothing partial or bad is written).
    func applyImport(_ plan: AgentImportPlan) {
        guard plan.hasApplicableChanges else { return }
        agents.append(contentsOf: plan.additions)
        for updated in plan.updates {
            if let index = agents.firstIndex(where: { $0.id == updated.id }) {
                agents[index] = updated
            }
        }
        persist()
    }

    private func persist() {
        try? store?.save(agents)
    }

    private func persistOptions() {
        try? optionsStore?.save(options)
    }
}
