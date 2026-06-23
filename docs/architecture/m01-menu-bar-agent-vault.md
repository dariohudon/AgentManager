# M01 — Menu Bar Agent Vault (Architecture)

> Status: scope-locked (M01-S01). This document defines what M01 builds and what it
> deliberately leaves out. No Swift code is written in M01-S01; this is the blueprint
> the implementation sprints follow.

## 1. V1 Product Scope

Agent Manager V1 is a **native macOS menu bar app** that acts as a local vault of
reusable AI agents. The user opens the vault from the menu bar, picks an agent, and
copies its prompt to the clipboard.

In scope for M01:

- A menu bar (status item) app with no Dock-first window requirement.
- Store, list, add, edit, and delete agents.
- Each agent holds: `name`, `title`, `description`, `prompt`.
- **Copy prompt to clipboard** as the primary, one-action-away interaction.
- Open the vault via a global/registered keyboard shortcut.
- Persist agents locally as JSON on disk.

## 2. Non-goals

Explicitly **not** part of M01:

- Workflows / multi-step orchestration
- Handoffs as an in-app feature
- Review packets
- Cloud sync or multi-device sync
- Backend service or API
- PM2 / server deployment
- Public staging or production deployment
- Chrome extension or any browser injection
- Migration from the old Prompt Manager codebase
- Third-party dependencies (M01 uses only the Apple SDK)

## 3. Core Data Model

A single primary entity: **Agent**.

```
Agent
├─ id:          UUID        // stable identifier
├─ name:        String      // short handle (e.g. "code-reviewer")
├─ title:       String      // human-friendly label (e.g. "Code Reviewer")
├─ description: String      // what the agent is for
├─ prompt:      String      // the reusable prompt text that gets copied
├─ createdAt:   Date
└─ updatedAt:   Date
```

The on-disk vault is the collection of agents:

```
AgentVault
└─ agents: [Agent]
```

Notes:

- `id`, `createdAt`, and `updatedAt` are implementation conveniences; the four
  user-facing fields required by the acceptance criteria are `name`, `title`,
  `description`, and `prompt`.
- Data is treated immutably in the UI layer: edits produce a new `Agent` value
  rather than mutating in place.

## 4. Planned App Structure

A small SwiftUI + AppKit-status-item app, organized by feature:

```
AgentManager/
├─ App/
│  ├─ AgentManagerApp.swift     // @main, MenuBarExtra / status item setup
│  └─ AppState.swift            // observable store, owns the loaded vault
├─ Models/
│  └─ Agent.swift               // Agent + AgentVault, Codable
├─ Persistence/
│  └─ AgentStore.swift          // load/save vault to local JSON
├─ Features/
│  ├─ Vault/
│  │  ├─ VaultView.swift        // list of agents, search/select
│  │  └─ AgentRow.swift         // row with copy-prompt action
│  └─ Editor/
│     └─ AgentEditorView.swift  // add/edit agent form
└─ Support/
   └─ Clipboard.swift           // copy prompt helper (NSPasteboard)
```

This is a target layout for the implementation sprints, not a contract; file
boundaries may shift slightly as M01 is built, but the feature-oriented grouping holds.

## 5. Menu Bar Behavior

- The app runs as a **menu bar / status item app** (e.g. SwiftUI `MenuBarExtra` or an
  `NSStatusItem`). It is the primary surface; there is no required main window in V1.
- Clicking the status item opens a popover/panel listing the stored agents.
- Each agent row exposes the primary **Copy prompt** action; copying gives clear,
  lightweight confirmation feedback.
- Secondary actions (add / edit / delete) are reachable from the same surface.
- The app stays resident in the menu bar; closing the popover does not quit it.

## 6. Keyboard Shortcut Behavior

- A keyboard shortcut opens the vault popover from anywhere, so copying a prompt is
  fast and keyboard-driven.
- Within the open vault, arrow keys move selection and Return/Enter triggers the
  primary **Copy prompt** action for the selected agent.
- Escape dismisses the popover.
- The exact key combination is finalized during implementation; M01 only commits to
  *having* a shortcut to open the vault and a key to copy the selected prompt.

## 7. Local JSON Persistence Choice

V1 persists the vault as a single local JSON file:

- Location: under the app's Application Support directory
  (e.g. `~/Library/Application Support/AgentManager/agents.json`).
- Format: `Agent` / `AgentVault` are `Codable`; the store serializes to and from JSON.
- Rationale:
  - Local-first and dependency-free — no database engine, no backend.
  - Human-readable and git-friendly if the user chooses to track it.
  - Trivial to back up, inspect, or hand-edit.
- Writes are atomic (write to a temp file, then replace) to avoid corrupting the vault
  on partial writes.

## 8. M01 Card Sequence

Card order for the M01 milestone (mirrors BATON):

1. **M01-S01 — Product Scope Lock** *(this card)* — documentation only: charter,
   operational state, and this architecture blueprint.
2. **M01-S02 — Menu Bar App Shell** — create the menu bar app skeleton (status item /
   `MenuBarExtra`), no persistence yet.
3. **M01-S03 — Agent Data Model and Seed Data** — `Agent`/`AgentVault` models plus
   initial seed data.
4. **M01-S04 — Agent List and Detail UI** — list agents and show an agent's detail.
5. **M01-S05 — Copy Prompt Action** — implement the primary copy-prompt-to-clipboard
   action.
6. **M01-S06 — Local JSON Persistence** — local JSON `AgentStore` (load/save, atomic
   writes).
7. **M01-S07 — Global Keyboard Shortcut** — open the vault via a global shortcut and
   copy the selected agent's prompt from the keyboard.
8. **M01-S08 — Codex Review and M01 Lock** — final review and lock of the M01
   milestone.

This sequence mirrors the current BATON cards; later cards may be adjusted as M01
progresses.
