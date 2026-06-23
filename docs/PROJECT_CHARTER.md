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
  - `preferredAI` (added in M02)
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

## M02 — Agent Library Polish + Metadata (complete)

M02 builds on the locked M01 foundation (no new product surfaces, still local-first):

- Category UX: headers larger/bold, categories collapsed by default, expand/collapse via
  `DisclosureGroup`; no hidden auto-selected agent on open.
- Preferred AI metadata: `Agent.preferredAI` (user-facing label "Preferred AI"; it is
  really a preferred tool/engine field). Default options: ChatGPT, Claude, Perplexity,
  Zapier, Descript — user-addable.
- Managed dropdowns: category and Preferred AI are dropdowns; users can add new options.
  Options persist locally in `~/Library/Application Support/AgentManager/options.json`
  (separate from `agents.json`, which stays a plain `[Agent]` array).
- Settings: an **inline** Settings mode (not a sheet/popover) behind an unobtrusive cog;
  manages app-level reusable options (categories, Preferred AI) and shows storage paths
  and shortcut info. No per-agent content lives in Settings.
- Duplicate Agent: copies the selected agent with a new `id`, fresh timestamps, name
  marked ` Copy`, preserving category/Preferred AI/title/description/prompt.

## Deferred to M02+ / M03

The deeper capability model is intentionally deferred:

- Inputs schema / Inputs Needed
- Output Format
- Examples library
- Validation checklists
- Version history / Change Log
- Usage tracking
- Capability engines: Claude Skills, Custom GPTs, MCP tools, automations, templates,
  checklists

## M03 direction (not implemented)

M03 is a **Native macOS Redesign**: move from a CRUD-over-JSON feel toward a native
macOS capability library that separates **Browse → Inspect → Edit**, with an eventual
Run/agent-execution direction. None of this is implemented in M02; `AgentBrowserView`
must remain reusable by both the `MenuBarExtra` surface and the standalone hotkey
`NSWindow`.

## Operating Model

- ChatGPT Web = Architect
- Claude Code = Implementer
- Codex = Reviewer
- BATON = workflow/project truth
- Local MacBook = working environment
- Xcode = native app environment
