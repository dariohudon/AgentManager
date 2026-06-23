import XCTest
@testable import AgentManager

final class AgentManagerTests: XCTestCase {
    func testProjectBootstraps() {
        XCTAssertTrue(true)
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
