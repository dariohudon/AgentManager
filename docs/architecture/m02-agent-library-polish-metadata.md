# M02 — Agent Library Polish + Metadata (Architecture)

> Status: M02 complete, pending final Codex lock (M02-S05). Builds on the locked M01
> foundation in [m01-menu-bar-agent-vault.md](m01-menu-bar-agent-vault.md). M02 added UX
> polish and metadata/management affordances — no new product surfaces, still local-first.

## 1. Scope delivered

- **M02-S01 — Category UX Polish.** Sidebar categories are collapsible `DisclosureGroup`s
  with larger/bold headers, collapsed by default (per-open `@State`, not persisted). No
  agent is auto-selected on open (avoids selecting one hidden in a collapsed category).
- **M02-S02 — Preferred AI Field and Managed Dropdowns.** `Agent.preferredAI` added;
  category and Preferred AI are dropdowns in the editor; users can add new options.
- **M02-S03 — Settings Gear.** An inline Settings mode behind an unobtrusive cog.
- **M02-S04 — Duplicate Agent.** Duplicate the selected agent from the detail pane.

## 2. Data model changes

`Agent` gains `preferredAI: String` (default `Agent.defaultPreferredAI` = "ChatGPT").
Decoding stays backward-compatible: missing `category` → "General", missing
`preferredAI` → "ChatGPT", so older JSON loads safely. Full field set:

```
Agent { id, category, preferredAI, name, title, description, prompt, createdAt, updatedAt }
```

## 3. Managed options

`LibraryOptions { categories: [String], preferredAIs: [String] }` holds user-managed
dropdown options, persisted by `OptionsStore` as JSON.

- Category choices = agent categories ∪ custom `options.categories` ∪ default category.
- Preferred AI choices = stored list, guaranteed to include the built-in defaults
  (ChatGPT, Claude, Perplexity, Zapier, Descript).
- `AgentVault` owns the options and exposes `addCategoryOption` / `addPreferredAIOption`,
  which persist to `options.json`. Both the editor and Settings call these same methods.

## 4. Storage

- Agents: `~/Library/Application Support/AgentManager/agents.json` — still a plain
  `[Agent]` JSON array (unchanged format; `preferredAI` is just a new per-agent field).
- Options: `~/Library/Application Support/AgentManager/options.json` — `LibraryOptions`.
  First run writes the default options.

Keeping options in a separate file preserved `agents.json` backward compatibility.

## 5. UI structure (inline modes)

`AgentBrowserView` drives an inline `Mode` enum — `browse`, `editor`, `confirmDelete`,
`settings` — instead of `.sheet`/`.popover`/`.confirmationDialog`/`.alert`. This is the
M01 lesson: modals attached to a `MenuBarExtra` popover get dismissed when focus moves.
The same `AgentBrowserView` (via `ContentView`) backs both the menu bar popover and the
standalone hotkey window, so every surface behaves identically.

- Editor: Name, Category (dropdown + Add…), Preferred AI (dropdown + Add…), Title,
  Description, Prompt.
- Detail: category + Preferred AI badges; Copy Prompt (unchanged — only `agent.prompt`),
  Edit, Duplicate, Delete.
- Settings: Categories list + Add…, Preferred AI list + Add…, and App Info (agents/options
  storage paths, Control + Option + Space shortcut). App-level options only.

## 6. Duplicate behavior

`AgentVault.duplicate(id:now:)` creates a new `Agent` with a fresh `id` and timestamps,
name `"<name> Copy"`, preserving category/preferredAI/title/description/prompt; it
persists and returns the copy. The browser expands the copy's category and selects it.

## 7. Known limitations

- Options are add-only (no delete/rename) to avoid data-integrity issues with categories
  already assigned to agents.
- Duplicating a duplicate yields `Name Copy Copy` (no uniqueness logic).
- Collapse state is per-open (resets each time the surface opens).
- Live GUI flows are human spot-checked; data/persistence paths are unit-tested.

## 8. M03 direction (not implemented)

Native macOS Redesign: shift from a CRUD-over-JSON feel toward a native capability
library separating **Browse → Inspect → Edit**, with an eventual Run/agent-execution
direction. `AgentBrowserView` must stay reusable across both surfaces. Future Agent
pages should preserve direction toward Inputs Needed, Output Format, Validation
Checklist, Examples, and Change Log / Versions.
