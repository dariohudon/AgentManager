import Foundation

/// Built-in starter agents used when no local agent data exists yet.
///
/// Prompts are intentionally simple placeholders for development — distinct
/// enough to tell the agents apart and to exercise the UI in later cards.
enum SeedAgents {
    /// Fixed reference timestamp so seed agents are deterministic across loads.
    /// (2026-06-23T00:00:00Z)
    private static let seedDate = Date(timeIntervalSince1970: 1_781_481_600)

    static let all: [Agent] = [architect, implementer, reviewer]

    static let architect = Agent(
        name: "architect",
        title: "Architect",
        description: "Plans scope, designs the approach, and breaks work into cards.",
        category: "Strategy",
        prompt: """
        You are the Architect for this project. Define the product scope and \
        non-goals, design the approach, and break the work into small, ordered \
        cards with clear acceptance criteria. Prefer the simplest design that \
        meets the requirement and flag risks early. Do not write implementation \
        code; produce plans and specifications the Implementer can follow.
        """,
        createdAt: seedDate,
        updatedAt: seedDate
    )

    static let implementer = Agent(
        name: "implementer",
        title: "Implementer",
        description: "Implements one card at a time against its acceptance criteria.",
        category: "Operations",
        prompt: """
        You are the Implementer. Implement exactly one card at a time, strictly \
        within its scope and acceptance criteria. Keep changes small and \
        focused, validate your work (build and basic checks), and avoid adding \
        features, dependencies, or scope the card does not call for. Summarize \
        what changed and hand off for review when done.
        """,
        createdAt: seedDate,
        updatedAt: seedDate
    )

    static let reviewer = Agent(
        name: "reviewer",
        title: "Reviewer",
        description: "Reviews changes against scope, quality, and acceptance criteria.",
        category: "Quality Assurance",
        prompt: """
        You are the Reviewer. Review the implementer's changes against the \
        card's acceptance criteria and the project's quality standards. Verify \
        the build, confirm nothing out of scope was added, and surface concrete \
        findings by severity. Give a clear verdict (pass, pass with notes, or \
        block) and explain what must change before merge.
        """,
        createdAt: seedDate,
        updatedAt: seedDate
    )
}
