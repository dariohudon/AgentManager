# Agent Manager — Current Operational State

## Status

M02 implementation is complete and ready for final Codex lock review (M02-S05).

## Current Milestone

M02 - Agent Library Polish + Metadata

## Current Branch

m02-s05-codex-review-m02-lock

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

## M03 Direction (not implemented)

- Native macOS Redesign: move from a CRUD-over-JSON feel to a native capability library.
- Separate Browse → Inspect → Edit.
- Eventual Run / agent-execution direction (not in M02).

## Immediate Next Step

Final Codex review and M02 lock (M02-S05).
