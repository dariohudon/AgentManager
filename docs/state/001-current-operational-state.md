# Agent Manager — Current Operational State

## Status

M01 and M02 are locked. M03 (Native macOS Redesign) has begun with its direction lock
(M03-S01) — docs only; no product UI redesigned yet.

## Current Milestone

M03 - Native macOS Redesign (direction-locking)

## Current Branch

m03-s01-redesign-direction-lock

## Local Path

/Users/dario/AgentManager

## Shipped

`main` contains M01 (S01–S09) plus M02-S01 through M02-S04:

- M01 — Menu Bar Agent Vault (locked): menu bar app, Agent model + seed data,
  categorized list/detail, Copy Prompt, local JSON persistence, add/edit/delete,
  global shortcut + standalone hotkey window.
- M02-S01 — Category UX Polish: category headers larger/bold; collapsed by default;
  expand/collapse via `DisclosureGroup`; no hidden auto-selected agent on open.
- M02-S02 — Preferred AI Field and Managed Dropdowns: `Agent.preferredAI`; category and
  Preferred AI dropdowns; user-addable options; new `options.json`.
- M02-S03 — Settings Gear: inline Settings mode (not sheet/popover) behind a cog;
  app-level options + storage/shortcut info; no per-agent content.
- M02-S04 — Duplicate Agent: duplicate selected agent (new id, fresh timestamps,
  ` Copy` name, preserved fields), expands the copy's category and selects it.

## App Model

Agent Library → Category → Agent → Instructions (capability-first, not prompt-first).

## Agent Fields

`id`, `category`, `preferredAI`, `name`, `title`, `description`, `prompt`, `createdAt`,
`updatedAt`. Older JSON missing `category`/`preferredAI` loads with defaults
("General" / "ChatGPT").

## Storage

- Agents: `~/Library/Application Support/AgentManager/agents.json` (plain `[Agent]` array)
- Options: `~/Library/Application Support/AgentManager/options.json` (`LibraryOptions`)

## Options

- Categories are managed app-level options (derived from agents ∪ custom additions).
- Preferred AI options are managed app-level options.
- Default Preferred AI options: ChatGPT, Claude, Perplexity, Zapier, Descript.
- Options are added from either the agent editor or Settings (same persistence).

## Settings

- Inline mode (not a sheet/popover), reached via an unobtrusive cog.
- App-level reusable options only (categories, Preferred AI) plus storage/shortcut info.
- No per-agent content in Settings.

## Duplicate

- New `id` and fresh `createdAt`/`updatedAt`.
- Preserves category, Preferred AI, title, description, prompt.
- Marks the name with ` Copy`.

## Stable Decisions

- Native macOS menu bar app, Swift + SwiftUI; capability-first Agent Library.
- `AgentBrowserView` is reusable by both the `MenuBarExtra` surface and the standalone
  hotkey `NSWindow`.
- Preferred AI is user-facing wording for a preferred tool/engine field.
- Local-first JSON storage only; BATON-managed workflow.
- No Chrome extension, backend, cloud sync, browser injection, server deployment, in-app
  BATON integration, workflows/handoffs/review packets, or capability engines.

## Known Limitations

- No live GUI automation in reviews — interactive flows are spot-checked by a human;
  data/persistence paths are covered by unit tests.
- Managed options are add-only (no delete/rename yet) to avoid data-integrity issues
  with categories already assigned to agents.
- Duplicating a duplicate yields names like `Name Copy Copy` (no uniqueness logic).
- Local JSON only — no cloud sync or multi-device support.
- Control + Option + Space may conflict with the macOS input-source switching shortcut;
  if already claimed, registration fails (logged) and the app runs without it.
- The shortcut opens a real `NSWindow` because `MenuBarExtra` cannot be opened
  programmatically.

## M03 Direction (direction-locked, not yet implemented)

- Native macOS Redesign: move from a CRUD-over-JSON feel to a native capability library.
- Primary user flow: Browse agents → Select agent → Run/copy agent.
- Separate Browse → Inspect → Edit; inspect/read is default, edit is intentional.
- Primary action becomes Run-oriented (still copy-backed) and prepares for Open-in-AI.
- Destructive actions de-emphasized; Settings stays app-level only; the shared Agent
  Library surface stays reusable across the menu bar and hotkey window.
- Full direction + diagnosis + layout + sprint plan:
  `docs/architecture/m03-native-macos-redesign.md`.
- Planned sprints: S01 Direction Lock (this), S02 NavigationSplitView Foundation,
  S03 Native Materials and Visual Hierarchy, S04 Browse/Inspect/Edit Architecture,
  S05 Agent Detail Redesign, S06 Primary Run Action Direction, S07 Codex Review and M03
  Lock.

## Immediate Next Step

Codex review of the M03 direction lock (M03-S01), then M03-S02 (NavigationSplitView
Foundation).
