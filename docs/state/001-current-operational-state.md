# Agent Manager — Current Operational State

## Status

M01 implementation is complete and in final lock repair / review.

## Current Milestone

M01 - Menu Bar Agent Vault (final: capability-first Agent Library)

## Current Branch

m01-s10-final-docs-lock-fix

## Local Path

/Users/dario/AgentManager

## Shipped in M01

`main` contains M01-S01 through M01-S09:

- S01 Product Scope Lock
- S02 Menu Bar App Shell
- S03 Agent Data Model and Seed Data
- S04 Agent List and Detail UI
- S05 Copy Prompt Action
- S06 Local JSON Persistence
- S07 Add / Edit / Delete Agents
- S08 Categorized Agent Library
- S09 Global Keyboard Shortcut

## Stable Systems

- Native macOS menu bar app (`MenuBarExtra`)
- `Agent` model with `category` (plus id, name, title, description, prompt, createdAt,
  updatedAt)
- Seed agents (Architect → Strategy, Implementer → Operations, Reviewer → Quality
  Assurance)
- Categorized list/detail UI (sidebar grouped by category)
- Add / edit / delete agents via an inline editor (delete with confirmation)
- Local JSON persistence (`AgentStore`)
- Copy Prompt copies only the prompt text
- Global shortcut Control + Option + Space (Carbon `RegisterEventHotKey`)
- Standalone hotkey-opened Agent Manager window sharing the same store
- Architecture docs (`docs/architecture/m01-menu-bar-agent-vault.md`)

## Stable Decisions

- Native macOS menu bar app, Swift + SwiftUI
- Capability-first Agent Library: Agent Library → Category → Agent → Instructions
- Local-first JSON storage only
- Copy Prompt is the primary action and copies only the prompt
- BATON-managed workflow
- No Chrome extension, backend, cloud sync, browser injection, PM2/server deployment, or
  in-app BATON integration in M01

## Known Limitations

- Control + Option + Space may conflict with the macOS input-source switching shortcut
  when multiple input sources are enabled; if the combination is already claimed,
  registration fails (logged) and the app runs without the shortcut.
- No Accessibility (or other) permission is required for the shortcut (app-scoped Carbon
  hot key, not a global event tap).
- Local JSON persistence only — no cloud sync or multi-device support.
- Advanced capability tabs/engines (inputs, examples, validation, versions, usage,
  Claude Skills / Custom GPTs / MCP tools, automations, templates, checklists) are
  deferred to M02+.

## Storage Path

`~/Library/Application Support/AgentManager/agents.json`

## Immediate Next Step

Final Codex review and M01 lock (M01-S10).
