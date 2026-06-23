# Agent Manager — Project Charter

## Purpose

Agent Manager is a native macOS **menu bar app** that acts as a local, capability-first
**Agent Library**. It is not a flat prompt list — it organizes reusable AI agents by
capability and makes copying an agent's instructions one action away.

Final M01 mental model:

```
Agent Library
└─ Category
   └─ Agent / Capability
      └─ Instructions (prompt)
```

## V1 Scope (M01 — Menu Bar Agent Library)

- Native macOS app delivered as a **menu bar (status item) app**
- Xcode project, Swift + SwiftUI
- Local-first **JSON** persistence (no backend, no cloud)
  - Storage path: `~/Library/Application Support/AgentManager/agents.json`
- A capability-first **Agent Library** organized by **category**
- Each **Agent** has:
  - `id`
  - `category`
  - `name`
  - `title`
  - `description`
  - `prompt` (the instructions)
  - `createdAt`
  - `updatedAt`
- The agent list is grouped by category
- **Add, edit, and delete** agents (with delete confirmation)
- **Copy Prompt** copies only the agent's `prompt` text (no title/description/metadata)
- Long prompts stay readable (scrollable, selectable)
- **Global shortcut: Control + Option + Space** opens Agent Manager while it runs in the
  background. Because a SwiftUI `MenuBarExtra` popover cannot be opened
  programmatically, the shortcut opens a real standalone Agent Manager window that hosts
  the same Agent Library UI (sharing one underlying store); the menu bar item remains
  the normal entry point.

## V1 Non-goals

Explicitly **out of scope** for V1 / M01:

- Workflows
- Handoffs (as an app feature)
- Review packets
- Cloud sync / multi-device sync
- Backend service or API
- PM2 process or server deployment
- Public staging/production deployment
- Chrome extension
- Browser injection
- In-app BATON integration
- Advanced capability-engine system
- Migration from the old Prompt Manager codebase

## Deferred to M02+

The deeper capability model is intentionally deferred beyond M01:

- Inputs schema
- Examples library
- Validation checklists
- Version history
- Usage tracking
- Capability engines: Claude Skills, Custom GPTs, MCP tools, automations, templates,
  checklists

## Operating Model

- ChatGPT Web = Architect
- Claude Code = Implementer
- Codex = Reviewer
- BATON = workflow/project truth
- Local MacBook = working environment
- Xcode = native app environment
