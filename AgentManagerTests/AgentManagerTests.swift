import AppKit
import XCTest
@testable import AgentManager

final class AgentManagerTests: XCTestCase {
    func testProjectBootstraps() {
        XCTAssertTrue(true)
    }

    func testCopyTextIsExactlyThePrompt() {
        // The copied text must be the prompt verbatim — no title, name,
        // description, or metadata concatenated in.
        for agent in SeedAgents.all {
            XCTAssertEqual(PromptPasteboard.copyText(for: agent), agent.prompt)
        }
    }

    func testCopyWritesOnlyPromptToPasteboard() {
        // Use a uniquely named pasteboard so the user's real clipboard is untouched.
        let pasteboard = NSPasteboard(name: .init("AgentManagerTests.copy"))
        pasteboard.clearContents()

        let agent = SeedAgents.architect
        PromptPasteboard.copy(agent, to: pasteboard)

        XCTAssertEqual(pasteboard.string(forType: .string), agent.prompt)

        pasteboard.releaseGlobally()
    }

    func testSeedAgentsIncludeArchitectImplementerReviewer() {
        let names = Set(SeedAgents.all.map(\.name))
        XCTAssertTrue(names.isSuperset(of: ["architect", "implementer", "reviewer"]))
    }

    func testSeedAgentsHaveDistinctNonEmptyPrompts() {
        let prompts = SeedAgents.all.map(\.prompt)
        XCTAssertFalse(prompts.contains(where: \.isEmpty))
        XCTAssertEqual(Set(prompts).count, prompts.count)
    }

    func testAgentRoundTripsThroughCodable() throws {
        let agent = SeedAgents.architect
        let data = try JSONEncoder().encode(agent)
        let decoded = try JSONDecoder().decode(Agent.self, from: data)
        XCTAssertEqual(decoded, agent)
    }

    // MARK: - Persistence (M01-S06)

    /// A unique temporary store URL so tests never touch the real app data at
    /// ~/Library/Application Support/AgentManager/agents.json.
    private func makeTempStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentManagerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("agents.json", isDirectory: false)
    }

    func testFirstRunWritesSeedWhenNoFileExists() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AgentStore(storeURL: url)

        XCTAssertFalse(store.hasLocalData)
        let loaded = try store.load()

        XCTAssertEqual(loaded, SeedAgents.all)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testExistingJSONLoadsSavedAgents() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let custom = [SeedAgents.reviewer, SeedAgents.architect]
        try AgentStore(storeURL: url).save(custom)

        // A fresh store at the same path simulates a later app launch.
        let reopened = AgentStore(storeURL: url)
        XCTAssertEqual(try reopened.load(), custom)
    }

    func testSaveRoundTrips() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AgentStore(storeURL: url)

        try store.save(SeedAgents.all)
        XCTAssertEqual(try store.load(), SeedAgents.all)
    }

    func testLoadDoesNotReseedWhenFileExists() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = AgentStore(storeURL: url)
        try store.save([SeedAgents.implementer])

        // Data survives "restart" and is not overwritten by the seed.
        XCTAssertEqual(try store.load(), [SeedAgents.implementer])
    }

    // MARK: - Add / Edit / Delete (M01-S07)

    private static let fixedDate = Date(timeIntervalSince1970: 2_000_000_000)

    func testAddPersistsNewAgentAndSurvivesRestart() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(store: AgentStore(storeURL: url), optionsStore: nil)
        let before = vault.agents.count

        let added = vault.add(
            name: "scout",
            title: "Scout",
            description: "Finds things",
            category: "Research",
            preferredAI: "Perplexity",
            prompt: "You are the Scout.",
            now: Self.fixedDate
        )

        XCTAssertEqual(vault.agents.count, before + 1)
        XCTAssertEqual(added.category, "Research")
        XCTAssertEqual(added.preferredAI, "Perplexity")
        XCTAssertEqual(added.createdAt, Self.fixedDate)
        XCTAssertEqual(added.updatedAt, Self.fixedDate)

        // Reload from disk = simulated restart.
        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertEqual(reloaded.count, before + 1)
        XCTAssertTrue(reloaded.contains { $0.id == added.id && $0.category == "Research" })
    }

    func testEditUpdatesFieldsBumpsUpdatedAtAndPreservesCreatedAt() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(store: AgentStore(storeURL: url), optionsStore: nil)
        let original = vault.agents[0]

        vault.update(
            id: original.id,
            name: "renamed",
            title: "Renamed",
            description: "new desc",
            category: "Recategorized",
            preferredAI: "Claude",
            prompt: "new prompt",
            now: Self.fixedDate
        )

        let edited = try XCTUnwrap(vault.agents.first { $0.id == original.id })
        XCTAssertEqual(edited.prompt, "new prompt")
        XCTAssertEqual(edited.category, "Recategorized")
        XCTAssertEqual(edited.preferredAI, "Claude")
        XCTAssertEqual(edited.createdAt, original.createdAt)
        XCTAssertEqual(edited.updatedAt, Self.fixedDate)

        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertEqual(reloaded.first { $0.id == original.id }?.category, "Recategorized")
    }

    func testDuplicateCopiesFieldsWithNewIdFreshTimestampsAndCopyName() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(store: AgentStore(storeURL: url), optionsStore: nil)
        let original = vault.agents[0]
        let before = vault.agents.count

        let copy = try XCTUnwrap(vault.duplicate(id: original.id, now: Self.fixedDate))

        XCTAssertEqual(vault.agents.count, before + 1)
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.createdAt, Self.fixedDate)
        XCTAssertEqual(copy.updatedAt, Self.fixedDate)
        XCTAssertEqual(copy.name, "\(original.name) Copy")
        XCTAssertEqual(copy.title, original.title)
        XCTAssertEqual(copy.description, original.description)
        XCTAssertEqual(copy.category, original.category)
        XCTAssertEqual(copy.preferredAI, original.preferredAI)
        XCTAssertEqual(copy.prompt, original.prompt)

        // Persists and survives "restart".
        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertTrue(reloaded.contains { $0.id == copy.id && $0.name == copy.name })
    }

    func testDeleteRemovesAgentAndStaysDeletedAfterRestart() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(store: AgentStore(storeURL: url), optionsStore: nil)
        let victim = vault.agents[0]

        vault.delete(id: victim.id)

        XCTAssertFalse(vault.agents.contains { $0.id == victim.id })

        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertFalse(reloaded.contains { $0.id == victim.id })
    }

    // MARK: - Categories (M01-S08)

    func testSeedAgentsHaveExpectedCategories() {
        XCTAssertEqual(SeedAgents.architect.category, "Strategy")
        XCTAssertEqual(SeedAgents.implementer.category, "Operations")
        XCTAssertEqual(SeedAgents.reviewer.category, "Quality Assurance")
    }

    func testCategoryEncodesAndDecodes() throws {
        let agent = SeedAgents.architect
        let data = try JSONEncoder().encode(agent)

        // category is written to JSON...
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"category\""))
        XCTAssertTrue(json.contains("Strategy"))

        // ...and round-trips.
        let decoded = try JSONDecoder().decode(Agent.self, from: data)
        XCTAssertEqual(decoded, agent)
    }

    func testLegacyJSONWithoutCategoryDefaultsToGeneral() throws {
        // A record saved before categories existed (no "category" key).
        let legacy = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "name": "legacy",
          "title": "Legacy",
          "description": "Saved before categories existed",
          "prompt": "Legacy prompt",
          "createdAt": 0,
          "updatedAt": 0
        }
        """
        let decoded = try JSONDecoder().decode(Agent.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.category, Agent.defaultCategory)
        XCTAssertEqual(decoded.category, "General")
    }

    func testCategorySurvivesSaveReload() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try AgentStore(storeURL: url).save(SeedAgents.all)

        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertEqual(reloaded.first { $0.name == "architect" }?.category, "Strategy")
        XCTAssertEqual(reloaded.first { $0.name == "reviewer" }?.category, "Quality Assurance")
    }

    // MARK: - Preferred AI + managed dropdowns (M02-S02)

    /// A unique temporary options-store URL, isolated from real app data.
    private func makeTempOptionsURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentManagerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("options.json", isDirectory: false)
    }

    func testSeedAgentsHaveExpectedPreferredAI() {
        XCTAssertEqual(SeedAgents.architect.preferredAI, "ChatGPT")
        XCTAssertEqual(SeedAgents.implementer.preferredAI, "Claude")
        XCTAssertEqual(SeedAgents.reviewer.preferredAI, "ChatGPT")
    }

    func testPreferredAIEncodesAndDecodes() throws {
        let agent = SeedAgents.implementer
        let data = try JSONEncoder().encode(agent)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"preferredAI\""))

        let decoded = try JSONDecoder().decode(Agent.self, from: data)
        XCTAssertEqual(decoded, agent)
        XCTAssertEqual(decoded.preferredAI, "Claude")
    }

    func testLegacyJSONWithoutPreferredAIDefaultsToChatGPT() throws {
        // A record saved before category/preferredAI existed.
        let legacy = """
        {
          "id": "00000000-0000-0000-0000-000000000002",
          "name": "legacy",
          "title": "Legacy",
          "description": "Saved before preferredAI existed",
          "prompt": "Legacy prompt",
          "createdAt": 0,
          "updatedAt": 0
        }
        """
        let decoded = try JSONDecoder().decode(Agent.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.preferredAI, Agent.defaultPreferredAI)
        XCTAssertEqual(decoded.preferredAI, "ChatGPT")
    }

    func testDefaultPreferredAIOptionsExist() {
        let vault = AgentVault(agents: SeedAgents.all)
        for expected in ["ChatGPT", "Claude", "Perplexity", "Zapier", "Descript"] {
            XCTAssertTrue(vault.preferredAIChoices.contains(expected), "missing \(expected)")
        }
    }

    func testCategoryChoicesUseExistingCategories() {
        let vault = AgentVault(agents: SeedAgents.all)
        let choices = vault.categoryChoices
        XCTAssertTrue(choices.contains("Strategy"))
        XCTAssertTrue(choices.contains("Operations"))
        XCTAssertTrue(choices.contains("Quality Assurance"))
        XCTAssertTrue(choices.contains(Agent.defaultCategory))
    }

    func testAddedPreferredAIOptionPersists() throws {
        let url = makeTempOptionsURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(agents: SeedAgents.all, optionsStore: OptionsStore(storeURL: url))

        vault.addPreferredAIOption("Gemini")
        XCTAssertTrue(vault.preferredAIChoices.contains("Gemini"))

        let reloaded = try OptionsStore(storeURL: url).load()
        XCTAssertTrue(reloaded.preferredAIs.contains("Gemini"))
    }

    func testAddedCategoryOptionPersists() throws {
        let url = makeTempOptionsURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(agents: SeedAgents.all, optionsStore: OptionsStore(storeURL: url))

        vault.addCategoryOption("Research")
        XCTAssertTrue(vault.categoryChoices.contains("Research"))

        let reloaded = try OptionsStore(storeURL: url).load()
        XCTAssertTrue(reloaded.categories.contains("Research"))
    }

    // MARK: - Display sanitization (M03-S06.5)

    func testSanitizedForDisplayTreatsPlaceholdersAsEmpty() {
        XCTAssertNil("".sanitizedForDisplay)
        XCTAssertNil("   ".sanitizedForDisplay)
        XCTAssertNil("-".sanitizedForDisplay)
        XCTAssertNil("--".sanitizedForDisplay)
        XCTAssertNil("—".sanitizedForDisplay)
        XCTAssertNil("–".sanitizedForDisplay)
        XCTAssertNil("  --  ".sanitizedForDisplay)
    }

    func testSanitizedForDisplayKeepsRealText() {
        XCTAssertEqual("Reviewer".sanitizedForDisplay, "Reviewer")
        XCTAssertEqual("  Reviewer  ".sanitizedForDisplay, "Reviewer")
        // Dashes are fine when there's real content around them.
        XCTAssertEqual("multi-step".sanitizedForDisplay, "multi-step")
    }

    func testOptionsStoreFirstRunWritesDefaults() throws {
        let url = makeTempOptionsURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = OptionsStore(storeURL: url)

        XCTAssertFalse(store.hasLocalData)
        let loaded = try store.load()
        XCTAssertEqual(loaded, .initial)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Agent Pack import/export (M05-S01)

    func testExportLibraryRoundTripsToUnchangedImport() throws {
        let pack = AgentPackService.makeLibraryPack(agents: SeedAgents.all, now: Self.fixedDate)
        XCTAssertEqual(pack.packType, "library")
        XCTAssertEqual(pack.schemaVersion, AgentPack.currentSchemaVersion)

        let json = try AgentPackService.encode(pack)
        let decoded = try AgentPackService.decode(json)
        try AgentPackService.validate(decoded)

        // Re-importing an export of the same agents should be all-unchanged.
        let plan = AgentPackService.plan(pack: decoded, existing: SeedAgents.all, now: Self.fixedDate)
        XCTAssertEqual(plan.addCount, 0)
        XCTAssertEqual(plan.updateCount, 0)
        XCTAssertEqual(plan.errorCount, 0)
        XCTAssertEqual(plan.unchangedCount, SeedAgents.all.count)
        XCTAssertFalse(plan.hasApplicableChanges)
    }

    func testImportPlanAddsNewAgent() {
        let pack = AgentPack(
            schemaVersion: 1, packType: "agent", name: "t", description: nil,
            createdBy: nil, updatedAt: nil, importMode: "merge", categories: nil,
            agents: [PackAgent(slug: "scout", name: "scout", title: "Scout",
                               category: "Research", preferredAI: "Perplexity",
                               purpose: "Finds things", instructions: "You are the Scout.")]
        )
        let plan = AgentPackService.plan(pack: pack, existing: SeedAgents.all, now: Self.fixedDate)
        XCTAssertEqual(plan.addCount, 1)
        XCTAssertEqual(plan.updateCount, 0)
        XCTAssertEqual(plan.additions.first?.name, "scout")
        XCTAssertEqual(plan.additions.first?.category, "Research")
    }

    func testImportPlanUpdatesExistingBySlugNotDuplicate() {
        // Same slug as a seed agent ("architect") but a changed prompt → update.
        let pack = AgentPack(
            schemaVersion: 1, packType: "agent", name: "t", description: nil,
            createdBy: nil, updatedAt: nil, importMode: "merge", categories: nil,
            agents: [PackAgent(slug: "architect", name: "architect", title: "Architect",
                               category: "Strategy", preferredAI: "ChatGPT",
                               purpose: "Plans.", instructions: "Updated instructions.")]
        )
        let plan = AgentPackService.plan(pack: pack, existing: SeedAgents.all, now: Self.fixedDate)
        XCTAssertEqual(plan.addCount, 0)
        XCTAssertEqual(plan.updateCount, 1)
        // The update preserves the existing agent's id.
        XCTAssertEqual(plan.updates.first?.id, SeedAgents.architect.id)
        XCTAssertEqual(plan.updates.first?.prompt, "Updated instructions.")
    }

    func testImportPlanMissingInstructionsIsError() {
        let pack = AgentPack(
            schemaVersion: 1, packType: "agent", name: "t", description: nil,
            createdBy: nil, updatedAt: nil, importMode: "merge", categories: nil,
            agents: [PackAgent(slug: "broken", name: "broken", title: nil,
                               category: nil, preferredAI: nil, purpose: nil, instructions: "  ")]
        )
        let plan = AgentPackService.plan(pack: pack, existing: SeedAgents.all, now: Self.fixedDate)
        XCTAssertEqual(plan.errorCount, 1)
        XCTAssertEqual(plan.addCount, 0)
        XCTAssertEqual(plan.updateCount, 0)
    }

    func testImportRejectsMalformedJSON() {
        XCTAssertThrowsError(try AgentPackService.decode("{ not valid json")) { error in
            XCTAssertEqual(error as? AgentPackError, .malformedJSON)
        }
    }

    func testImportRejectsUnsupportedSchemaVersion() throws {
        let pack = AgentPack(
            schemaVersion: 999, packType: "library", name: nil, description: nil,
            createdBy: nil, updatedAt: nil, importMode: nil, categories: nil,
            agents: [PackAgent(slug: "a", name: "a", title: nil, category: nil,
                               preferredAI: nil, purpose: nil, instructions: "x")]
        )
        XCTAssertThrowsError(try AgentPackService.validate(pack)) { error in
            XCTAssertEqual(error as? AgentPackError, .unsupportedSchemaVersion(found: 999, supported: AgentPack.currentSchemaVersion))
        }
    }

    func testApplyImportAddsAndUpdatesAndPersists() throws {
        let url = makeTempStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let vault = AgentVault(store: AgentStore(storeURL: url), optionsStore: nil)
        let before = vault.agents.count

        let pack = AgentPack(
            schemaVersion: 1, packType: "library", name: nil, description: nil,
            createdBy: nil, updatedAt: nil, importMode: "merge", categories: nil,
            agents: [
                PackAgent(slug: "scout", name: "scout", title: "Scout", category: "Research",
                          preferredAI: "Perplexity", purpose: "Finds", instructions: "Be the Scout."),
                PackAgent(slug: "architect", name: "architect", title: "Architect", category: "Strategy",
                          preferredAI: "ChatGPT", purpose: "Plans", instructions: "New architect instructions."),
            ]
        )
        let plan = AgentPackService.plan(pack: pack, existing: vault.agents, now: Self.fixedDate)
        XCTAssertEqual(plan.addCount, 1)
        XCTAssertEqual(plan.updateCount, 1)

        vault.applyImport(plan)
        XCTAssertEqual(vault.agents.count, before + 1)

        let reloaded = try AgentStore(storeURL: url).load()
        XCTAssertTrue(reloaded.contains { $0.name == "scout" })
        XCTAssertEqual(reloaded.first { $0.name == "architect" }?.prompt, "New architect instructions.")
    }
}
