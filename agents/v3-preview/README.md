# V3 Preview (DRAFT — not live)

This directory holds **draft Kiro CLI V3 agent prototypes**. They exist only to de-risk the
eventual v2 → v3 migration. They are **not loaded by the 2.x engine** (which loads `agents/*.json`),
and they must **not** be promoted to `~/.kiro/agents/` until:

1. AWS publishes the official v2 → v3 migration guide, and
2. We validate on `kiro-cli --v3` (`kiro-cli diagnostic` passes, smoke test green).

## Contents

- `master.md` — V3 Markdown translation of `agents/master.json` + `prompts/master.md`. Demonstrates
  the format shift: JSON → Markdown frontmatter, `tools:["*"]` → tag list, inline `mcpServers`,
  `toolsSettings` → `permissions:` block, system prompt as the document body.

## What still needs doing at migration time

- Inline the real `prompts/master.md` body (the draft uses a pointer to avoid drift).
- Move embedded `postToolUse` formatter hooks to standalone `.kiro/hooks/*.json`
  (`kiro-cli agent migrate` can auto-convert).
- Re-express remaining agents the same way.

Full mapping + checklist: `steering/kiro-cli-v3-migration.md`.
