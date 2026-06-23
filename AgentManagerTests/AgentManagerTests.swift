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
}
