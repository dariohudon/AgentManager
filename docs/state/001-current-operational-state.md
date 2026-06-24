# Agent Manager — Current Operational State

## Status

M01 and M02 are locked. **M03 (Native macOS Redesign) is complete and under final lock
review (M03-S07).** All of M03-S01 through M03-S06.5 are implemented and merged to main;
the app has been redesigned, not merely direction-locked.

## Current Milestone

M03 - Native macOS Redesign (complete / lock review)

## Current Branch

m03-s07-codex-review-m03-lock

## Local Path

/Users/dario/AgentManager

## Shipped

`main` contains M01 (S01–S09), M02 (S01–S04), and M03 (S01–S06.5):

- M01 — Menu Bar Agent Vault (locked): menu bar app, Agent model + seed data,
  categorized list/detail, Copy Prompt, local JSON persistence, add/edit/delete,
  global shortcut + standalone hotkey window.
- M02 — Agent Library Polish + Metadata (locked): category UX (collapsed by default),
  Preferred AI metadata + managed category/Preferred AI dropdowns, inline Settings,
  Duplicate Agent, `options.json`.
- M03 — Native macOS Redesign:
  - M03-S01 — Redesign Direction Lock
  - M03-S02 — NavigationSplitView Foundation
  - M03-S03 — Native Materials and Visual Hierarchy
  - M03-S04 — Browse / Inspect / Edit Architecture
  - M03-S05 — Agent Detail Redesign
  - M03-S06 — Primary Run Action Direction
  - M03-S06.5 — Visual QA + Store Polish Patch
  - M03-S07 — Final Review and Lock (in progress)

## App Model

Agent Library → Category → Agent → Instructions (capability-first, not prompt-first).

## Primary Flow

Browse agents → Select agent → Run/copy agent.

## M03 Implementation Realities

- **Persistent NavigationSplitView**: a sidebar navigator + detail column is the
  permanent foundation; editor / delete-confirm / Settings render in the detail column,
  not as modals.
- **Calm native visual hierarchy**: calmer rows and detail; clear primary/secondary/
  de-emphasized actions instead of equal-weight buttons.
- **Browse / Inspect / Edit separation**: selecting an agent shows read-only inspect by
  default; Edit is entered intentionally; New Agent is a quiet "+" control.
- **Agent detail redesigned**: clear name header, compact `Category • Preferred AI`
  metadata line, a **Purpose** section, and **Instructions** as the prominent scrollable
  star.
- **Run / Copy language bridge**: the primary action reads "Run / Copy" with honest
  helper text/tooltip. **Behavior is copy-only** — it copies `agent.prompt` to the
  clipboard via `PromptPasteboard.copy(agent)`. No real execution exists.
- **Dash-placeholder display sanitizer**: `String.sanitizedForDisplay` suppresses empty/
  whitespace/dash-only placeholders in rows, Purpose, and Instructions (display-level
  only; stored JSON is not mutated).
- **Neutral background fix**: `ContentView` uses an opaque native window background to
  remove accent/translucency bleed.
- **Editor no longer manages options**: the agent editor keeps Category and Preferred AI
  pickers but no longer adds options; option management lives in Settings.
- **Settings grouped and app-level**: a native grouped Form with Categories, Preferred
  AI, and a quieter App Info section. No per-agent content.

## Shared Surface

`MenuBarExtra` and the standalone hotkey `NSWindow` both render the same shared
`ContentView` → `AgentBrowserView` path over one `AgentVault`. There is no menu-bar-only
or hotkey-only UI path.

## Agent Fields

`id`, `category`, `preferredAI`, `name`, `title`, `description`, `prompt`, `createdAt`,
`updatedAt`. Older JSON missing `category`/`preferredAI` loads with defaults
("General" / "ChatGPT").

## Storage

- Agents: `~/Library/Application Support/AgentManager/agents.json` (plain `[Agent]` array)
- Options: `~/Library/Application Support/AgentManager/options.json` (`LibraryOptions`)

## Stable Decisions

- Native macOS menu bar app, Swift + SwiftUI; capability-first Agent Library.
- `AgentBrowserView` (via `ContentView`) is reusable by both the `MenuBarExtra` surface
  and the standalone hotkey `NSWindow`.
- Run / Copy is copy-backed only; it copies `agent.prompt` — no real execution.
- Settings remains app-level only (no per-agent content).
- Preferred AI is user-facing wording for a preferred tool/engine field.
- Local-first JSON storage only; BATON-managed workflow.
- No backend, cloud sync, browser injection, in-app BATON integration, real execution,
  workflows/handoffs/review packets, or external dependencies were added.

## Known Limitations

- No live GUI automation in reviews — interactive flows are spot-checked by a human;
  data/persistence/display logic is covered by unit tests.
- Managed options are add-only (no delete/rename yet).
- Duplicating a duplicate yields names like `Name Copy Copy` (no uniqueness logic).
- Local JSON only — no cloud sync or multi-device support.
- Control + Option + Space may conflict with the macOS input-source switching shortcut;
  if already claimed, registration fails (logged) and the app runs without it.
- The shortcut opens a real `NSWindow` because `MenuBarExtra` cannot be opened
  programmatically.

## Future Direction (not implemented)

The primary action's "Run / Copy" wording prepares for an eventual Run Agent / Open-in-
Preferred-AI model. No browser/API execution, integrations, or execution engine exists
today. Future Agent pages may add Inputs Needed, Output Format, Validation Checklist,
Examples, and Change Log / Versions.

## Immediate Next Step

Complete the M03-S07 final lock review and lock M03.
