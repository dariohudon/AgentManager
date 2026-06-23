# M01 — Menu Bar Agent Vault (Architecture)

> Status: scope-locked (M01-S01). This document defines what M01 builds and what it
> deliberately leaves out. No Swift code is written in M01-S01; this is the blueprint
> the implementation sprints follow.

## 1. V1 Product Scope

Agent Manager V1 is a **native macOS menu bar app** that acts as a local,
capability-first **Agent Library**. It is not a flat prompt list — it is organized
around capabilities. The mental model is:

```
Agent Library
└─ Category
   └─ Agent / Capability
      └─ Instructions (prompt)
```

The user opens the library from the menu bar, browses agents grouped by category,
picks one, and copies its instructions (prompt) to the clipboard.

In scope for M01:

- A menu bar (status item) app with no Dock-first window requirement.
- An Agent Library organized by **category**.
- Store, list, add, edit, and delete agents.
- Each agent holds: `name`, `title`, `description`, `category`, `prompt`.
- Agent list is grouped by category.
- **Copy prompt to clipboard** as the primary, one-action-away interaction.
- Open the library via a global/registered keyboard shortcut.
- Persist agents locally as JSON on disk.

Deferred to **M02+** (explicitly out of M01): the full tabbed Agent page and any
deeper capability modeling — inputs schema, examples library, validation checklists,
version history, usage tracking, and capability engines such as Claude Skills, Custom
GPTs, MCP tools, automations, templates, and checklists. M01 implements the smallest
practical Agent Library: categories, agents, instructions, add/edit/delete, and local
JSON persistence.

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
├─ category:    String      // capability grouping (e.g. "Strategy"); default "General"
├─ prompt:      String      // the instructions / reusable prompt text that gets copied
├─ createdAt:   Date
└─ updatedAt:   Date
```

The on-disk vault is the collection of agents (`AgentVault` in the UI layer is the
observable, persistence-backed store; on disk it is a JSON array of `Agent`):

```
AgentVault
└─ agents: [Agent]
```

Notes:

- `id`, `createdAt`, and `updatedAt` are implementation conveniences; the user-facing
  fields are `name`, `title`, `description`, `category`, and `prompt`.
- `category` groups agents in the library. Agents without a category — including JSON
  written before categories existed — default to `Agent.defaultCategory` (`"General"`),
  so older data files load safely.
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

- **Shortcut: Control + Option + Space** opens Agent Manager from anywhere while the
  app is running in the background (implemented in M01-S09).
- Implementation: a Carbon `RegisterEventHotKey` hot key (`GlobalHotKey`) scoped to the
  application's event target. On fire, the app activates and brings up a standalone
  Agent Library window (`AgentManagerWindowController`) hosting the same `ContentView`
  as the menu bar panel, backed by the shared `AgentVault`.
- Why a window, not the menu bar popover: SwiftUI `MenuBarExtra` popovers can't be
  opened programmatically, so the shortcut opens a real window instead of faking a
  menu-bar click. The menu bar item remains the normal entry point and keeps working;
  Quit still works from either surface.

### Constraints (macOS)

- **No special permissions required.** A Carbon app-scoped hot key does not need
  Accessibility permission (unlike a `CGEventTap`). It works system-wide only while
  Agent Manager is running.
- **Possible conflict.** Control + Option + Space can collide with the macOS
  input-source switching shortcut ("Select the next input source") when multiple input
  sources are enabled. If the combination is already claimed, `RegisterEventHotKey`
  fails; the app logs this and continues without the shortcut (the menu bar item still
  works). A user-configurable shortcut is out of scope for M01.

## 7. Local JSON Persistence Choice

V1 persists the vault as a single local JSON file (implemented in M01-S06 by
`AgentStore`):

- Location: `~/Library/Application Support/AgentManager/agents.json`
  (the app's Application Support directory). `AgentStore.defaultStoreURL`
  is the single source of truth for this path.
- Format: a JSON array of `Agent` (which is `Codable`), pretty-printed with
  sorted keys and ISO-8601 dates.
- First run: when no file exists, the seed agents are written to disk and
  returned. Subsequent runs decode and return the saved agents, so changes
  survive an app restart.
- Rationale:
  - Local-first and dependency-free — no database engine, no backend.
  - Human-readable and git-friendly if the user chooses to track it.
  - Trivial to back up, inspect, or hand-edit.
- Writes are atomic (`Data.write(options: .atomic)`) to avoid corrupting the
  vault on partial writes. The store also exposes a `save([Agent])` function
  that M01-S07 (Add/Edit/Delete) builds on.

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
7. **M01-S07 — Add / Edit / Delete Agents** — create, edit, and delete agents,
   persisting changes through `AgentStore.save`.
8. **M01-S08 — Categorized Agent Library** — add `category` to `Agent`, group the
   library by category, support category in add/edit, and frame the app as a
   capability-first Agent Library (not a flat prompt list).
9. **M01-S09 — Global Keyboard Shortcut** — open the library via a global shortcut and
   copy the selected agent's prompt from the keyboard.
10. **M01-S10 — Codex Review and M01 Lock** — final review and lock of the M01
    milestone.

Sequence note: Dario reframed M01 as a capability-first Agent Library and confirmed
category support is in scope, added here as **M01-S08**, which shifts the global
keyboard shortcut to **M01-S09** and the final review/lock to **M01-S10**. The BATON
cards have been reconciled to match. Advanced capability modeling (tabbed Agent page,
inputs, examples, validation, versions, usage, and capability engines like Claude
Skills / Custom GPTs / MCP tools) is deferred to M02+.
