# Agent Packs

Agent Packs are Agent Manager's versioned JSON exchange format for importing and exporting reusable AI agents.

They are intended for workflows where an AI Architect or external editor generates a structured pack that can be pasted into Agent Manager and safely previewed before import.

## Format

Current schema version: 1

Example JSON shape:

    {
      "schemaVersion": 1,
      "packType": "agent",
      "name": "Example Pack",
      "description": "A small example Agent Pack.",
      "createdBy": "Dario / Architect",
      "updatedAt": "2026-06-23T00:00:00Z",
      "importMode": "merge",
      "categories": [],
      "agents": [
        {
          "slug": "caption-writer",
          "name": "Caption Writer",
          "title": "Caption Writer",
          "category": "Content",
          "preferredAI": "ChatGPT",
          "purpose": "Writes platform-aware captions.",
          "instructions": "You are a caption-writing assistant..."
        }
      ]
    }

## Import behavior

Agent Manager previews imports before applying changes.

The preview can show:

- additions
- updates
- unchanged agents
- errors

Imports are not applied until the user confirms.

Invalid JSON and unsupported schema versions are rejected safely.

## Matching

Agent Pack matching prefers a stable slug when available.

If a slug is missing, the app may fall back to a safe identity such as name matching.

Agent title is not used as the primary matching identity.

## Storage

Agent Packs are an import/export exchange format.

They do not replace the app's local storage files:

    ~/Library/Application Support/AgentManager/agents.json
    ~/Library/Application Support/AgentManager/options.json

## Current limitations

Current M05-S01 implementation supports:

- paste-based import
- clipboard-based full-library export

Future cards may add:

- file import/export using .agentpack.json
- category-level export UI
- selected-agent export UI
- richer import conflict controls
