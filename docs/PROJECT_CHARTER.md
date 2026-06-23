# Agent Manager — Project Charter

## Purpose

Agent Manager is a native macOS app for managing reusable AI agents, prompts, workflows, handoffs, and review packets.

## V1 Scope

- Xcode project
- SwiftUI app shell
- Local-first data model
- Agents
- Prompts
- Workflows
- Handoffs
- Copy/export actions
- BATON workflow tracking

## V1 Non-goals

- Chrome extension
- Browser injection
- Backend service
- PM2 process
- Public staging/production deployment
- Cloud sync
- Migration from old Prompt Manager codebase

## Operating Model

- ChatGPT Web = Architect
- Claude Code = Implementer
- Codex = Reviewer
- BATON = workflow/project truth
- Local MacBook = working environment
- Xcode = native app environment
