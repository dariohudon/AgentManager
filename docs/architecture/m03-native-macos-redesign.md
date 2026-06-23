# M03 — Native macOS Redesign (Direction Lock)

> Status: direction-locked (M03-S01). This document fixes the M03 design direction
> BEFORE any UI is rebuilt. No product UI is redesigned in this card. Builds on the
> locked M01 ([m01-menu-bar-agent-vault.md](m01-menu-bar-agent-vault.md)) and M02
> ([m02-agent-library-polish-metadata.md](m02-agent-library-polish-metadata.md)).

## 1. Current assessment

- **Architecture: strong.** Clean model/store/vault layers; one reusable Agent Library
  surface backs both the menu bar popover and the hotkey window.
- **Functionality: strong.** Categories, Preferred AI metadata, managed dropdowns,
  inline Settings, duplicate, local JSON persistence, Copy Prompt, global shortcut.
- **macOS feel: weak.** Reads more like a cross-platform form than a native app.
- **Visual hierarchy: weak.** Everything has similar weight; the eye has no anchor.
- **Delight: low.** Nothing feels crafted or native-premium.

Net: the app is functional but visually and interaction-wise still feels like a **JSON
CRUD tool** — it treats every agent as an always-editable database record.

## 2. Core diagnosis

- Too many equal-weight buttons compete for attention (Copy/Edit/Duplicate/Delete all
  look similar).
- Edit/form mode feels like the main experience rather than an intentional action.
- The detail page has dead space and weak hierarchy.
- The sidebar/category list should be calmer and quieter.
- Empty descriptions/placeholders render as clutter instead of disappearing.
- The current yellow/settings-like background works against a calm native content
  workspace feel.

## 3. M03 design principles

1. **Capability-first, not prompt-first** — an agent is a capability; the prompt is its
   current instruction payload.
2. **Native macOS feel** — standard materials, spacing, and controls; calm surfaces.
3. **Separate Browse / Inspect / Edit** — these are distinct conceptual modes.
4. **Inspect (read) mode is the default** — selecting an agent shows it, it does not drop
   you into a form.
5. **Edit is intentional** — entered deliberately, not the resting state.
6. **Primary action is Run-oriented** — framed toward running the agent, while preserving
   today's Copy Prompt behavior until real execution exists.
7. **Destructive actions are secondary** — Delete is de-emphasized, never a peer of the
   primary action.
8. **Settings stays app-level only** — reusable options and app info; never per-agent
   content.
9. **One shared surface** — the Agent Library view (AgentBrowserView or its successor)
   remains reusable by both the `MenuBarExtra` surface and the standalone hotkey
   `NSWindow`. No divergent UI paths.

## 4. Desired layout direction

- Sidebar / navigator on the left; agent detail / inspection on the right
  (`NavigationSplitView`-shaped).
- Calmer category list — quieter rows, less visual noise.
- No description text in the sidebar when it is empty (don't render empty clutter).
- Main header showing the agent **name** as the anchor.
- A small metadata line beneath it: `Category • Preferred AI`.
- A **Purpose** section (reframing of Description) rather than a raw "Description" label.
- An **Instructions** section as the star of the detail view (the prompt, prominent and
  readable).
- Compact top-right actions: a **primary Run/Copy** action and **Edit**.
- **Delete** hidden / de-emphasized behind a secondary "more" affordance.

## 5. Future product direction (not implemented in M03 direction-lock)

- Copy Prompt is the current behavior and stays until real execution exists.
- The primary action's UI should prepare for **Open in Claude / ChatGPT / Gemini /
  Perplexity** later (informed by the agent's Preferred AI).
- This can eventually become **Run Agent**.
- No browser/API execution, no external integrations in M03 — direction only.

## 6. Future Agent page direction

Agent pages should eventually grow (beyond M03) to include:

- Inputs Needed
- Output Format
- Validation Checklist
- Examples
- Change Log / Versions

These are intentional future directions, not forgotten extras.

## 7. Proposed M03 sprint / card structure

1. **M03-S01 — Redesign Direction Lock** *(this card)* — docs only.
2. **M03-S02 — NavigationSplitView Foundation** — adopt a native split-view shell.
3. **M03-S03 — Native Materials and Visual Hierarchy** — materials, spacing, calmer
   surfaces, real hierarchy.
4. **M03-S04 — Browse / Inspect / Edit Architecture** — separate read vs edit modes;
   inspect is default, edit is intentional.
5. **M03-S05 — Agent Detail Redesign** — name header, `Category • Preferred AI` line,
   Purpose + Instructions sections, compact actions.
6. **M03-S06 — Primary Run Action Direction** — Run-oriented primary action (still
   copy-backed); prepare for Open-in-AI.
7. **M03-S07 — Codex Review and M03 Lock** — final review and lock.

## 8. Non-goals

- No backend
- No cloud sync
- No browser injection
- No external execution integrations
- No in-app BATON integration
- No workflows / handoffs product surface
- No advanced capability-engine system yet
- No separate UI implementations for the menu bar vs the hotkey window
