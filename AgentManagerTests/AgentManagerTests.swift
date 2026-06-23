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

    func testProviderReturnsSeedAgentsWhenNoLocalData() {
        let provider = AgentProvider()
        XCTAssertEqual(provider.loadAgents().map(\.name), SeedAgents.all.map(\.name))
    }
}
