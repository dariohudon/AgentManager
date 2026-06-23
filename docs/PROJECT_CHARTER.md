# Agent Manager — Project Charter

## Purpose

Agent Manager is a native macOS **menu bar app** for storing reusable AI agents and
copying their prompts to the clipboard. It is a local-first prompt vault that lives in
the menu bar and stays out of the way until you need an agent's prompt.

## V1 Scope (M01 — Menu Bar Agent Vault)

- Native macOS app delivered as a **menu bar (status item) app**
- Xcode project, Swift + SwiftUI
- Local-first storage (no backend, no cloud)
- Stores reusable **agents**, where each agent has:
  - `name`
  - `title`
  - `description`
  - `prompt`
- **Copy prompt to clipboard** is the primary action
- Minimal UI to add, edit, and delete agents
- Keyboard shortcut to open the menu bar vault

## V1 Non-goals

The following are explicitly **out of scope** for V1 / M01:

- Workflows
- Handoffs (as an app feature)
- Review packets
- Cloud sync
- Backend service
- PM2 process or server deployment
- Public staging/production deployment
- Chrome extension
- Browser injection
- Migration from the old Prompt Manager codebase

These may be reconsidered in a later milestone, but nothing here is required for V1.

## Operating Model

- ChatGPT Web = Architect
- Claude Code = Implementer
- Codex = Reviewer
- BATON = workflow/project truth
- Local MacBook = working environment
- Xcode = native app environment
