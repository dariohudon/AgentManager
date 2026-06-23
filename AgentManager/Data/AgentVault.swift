import Foundation
import Observation

/// Observable, in-memory collection of agents backed by `AgentStore`.
///
/// The vault loads agents on creation and persists every add/edit/delete
/// through `AgentStore.save`, so changes survive an app restart. Mutations
/// follow value semantics — an edit replaces an `Agent` with a new value rather
/// than mutating it in place.
@Observable
final class AgentVault {
    private(set) var agents: [Agent]

    private let store: AgentStore?

    /// Loads agents from the given store (the default Application Support store
    /// when omitted), falling back to the seed agents if the store can't be
    /// resolved or read.
    init(store: AgentStore? = AgentStore()) {
        self.store = store
        self.agents = store.flatMap { try? $0.load() } ?? SeedAgents.all
    }

    /// In-memory vault with explicit agents and no persistence. Intended for
    /// previews and tests of empty/seed states.
    init(agents: [Agent], store: AgentStore? = nil) {
        self.store = store
        self.agents = agents
    }

    /// Adds a new agent and persists. Returns the created agent.
    @discardableResult
    func add(
        name: String,
        title: String,
        description: String,
        category: String,
        prompt: String,
        now: Date = Date()
    ) -> Agent {
        let agent = Agent(
            name: name,
            title: title,
            description: description,
            category: category,
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
            prompt: prompt,
            createdAt: existing.createdAt,
            updatedAt: now
        )
        persist()
    }

    /// Deletes the agent with the given id and persists.
    func delete(id: Agent.ID) {
        agents.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        try? store?.save(agents)
    }
}
