---
inclusion: manual
name: kiro-cli-v3-migration
description: "v2 -> v3 migration mapping for this Kiro config. Manual inclusion — pull in only when planning or executing the Kiro CLI V3 migration. Covers agent JSON -> Markdown+tags, embedded hooks -> standalone .kiro/hooks/*.json, toolsSettings -> permissions, and a migration checklist."
---

# Kiro CLI v2 → v3 Migration Mapping

> **Status: ✅ COMPLETE (migrated Jul 18, 2026; bug fixed same day).** All 17 agents migrated to
> v3 Markdown format. Old JSON files retained as backup in `~/.kiro/agents/v2-backup/`.
> Hooks extracted to `~/.kiro/hooks/formatters.json` (global hooks, supported since CLI 2.13).

## How to run & validate V3 (READ THIS FIRST)

- **Run V3:** `kiro-cli chat --v3` (or `kiro-cli chat --agent-engine v3`). The bare global
  `kiro-cli --v3` also launches chat in V3. Tested on CLI **2.13.0**.
- **`agent` subcommands are V2/JSON-only.** `kiro-cli agent list` and `kiro-cli agent validate`
  do NOT understand V3 Markdown agents — `agent validate` errors with "invalid JSON … line 1
  column 2" on the `---` frontmatter, and `agent list` reports "user defined default master not
  found" because it only sees `.json`. This is expected; use them only for the V2 backups.
- **Validate V3 agents with `./validate.sh`** — Step 1 parses each agent's YAML frontmatter and
  tool tags (kiro-cli can't do it).
- **V2 and V3 run side by side.** Both formats live in `~/.kiro/agents/`: V2 (`kiro-cli chat`)
  loads the `*.json`; V3 (`kiro-cli chat --v3`) loads the `*.md` and **ignores** the `*.json`.
  Same 18 agents, same names, no conflict — verified: V2 `agent list` shows all 18; V3 registers
  all 18 with 0 parse failures and 0 `.json` in ProfileLoader. **The `.md` files are canonical:
  edit the `.md`, then run `./sync-agents.py`** to regenerate the `.json` + `prompts/` (shared
  fields: description, welcome, shortcut, mcpServers, prompt body, resources; V2-only fields like
  `tools`/`toolsSettings`/`hooks` are preserved). `validate.sh` Step 1.5 fails on drift. The
  `agents/v2-backup/` copies remain as a pristine pre-migration backup.

> ⚠️ **Root-cause bugs found & fixed (2026-07-18):**
> 1. **13 agents had `tools: [*]`** (bare star) — invalid YAML (a bare `*` is an alias), so the
>    frontmatter failed and V3 rejected the agent. The star MUST be quoted: **`tools: ["*"]`**.
> 2. **All agents had `permissions:` as a bare array** — V3's schema requires `permissions` to be an
>    **object with a `rules:` list**. The correct shape is:
>    ```yaml
>    permissions:
>      rules:
>        - capability: shell
>          effect: deny
>          match: ["git-defender*"]
>    ```
>    A bare-array `permissions:` throws `ZodError: Expected object, received array` and the agent
>    silently fails to load (confirmed in `~/.kiro/logs/*/kiro.log` via `[ProfileLoader] Failed to parse`).
>
> After both fixes all 17 agents register (verified: `grep "Registered user profile" ~/.kiro/logs/<newest>/kiro.log`).

## Migration Summary

| Item | Status |
|------|--------|
| Back up `~/.kiro/sessions/` | ✅ (not needed — JSON files kept as backup) |
| Convert all 17 agents to `.md` | ✅ Complete |
| Extract hooks to `.kiro/hooks/formatters.json` | ✅ Complete |
| Re-express `toolsSettings` as `permissions:` blocks | ✅ Complete |
| `ios` and `ios-testing` agents added | ✅ Complete |
| Orchestrator agents use explicit `subagent` tag | ✅ (master, web-builder, ai-builder) |
| `disabled: false` omitted (v3 default) | ✅ |
| `tools: ["*"]` → `tools: ["*"]` (quoted — bare `[*]` is invalid YAML) | ✅ Fixed 2026-07-18 |

## Agents Migrated (17)

1. `master.md` — ctrl+1, model: claude-opus-4.8
2. `serverless.md` — ctrl+4
3. `frontend.md` — ctrl+5
4. `testing.md` — ctrl+6
5. `ios.md` — ctrl+7
6. `ios-testing.md` — shift+t
7. `architect.md` — ctrl+8
8. `ai-builder.md` — ctrl+0
9. `devops.md` — ctrl+9
10. `data.md` — shift+d
11. `security.md` — shift+s
12. `docs.md` — shift+o
13. `image-gen.md` — shift+i
14. `research.md` — ctrl+2
15. `web-builder.md` — shift+w
16. `google-workspace.md` — (no shortcut)
17. `master-demo.md` — shift+m

## Hooks File

Location: `~/.kiro/hooks/formatters.json`

Contains 4 formatter hooks (corrected 2026-07-21 to the documented V3 shape — **`PostFileSave`**
trigger + file-extension regex matchers + the **`{{filePath}}`** template variable; the original
migration used `PostToolUse`/`fs_write` + V2's `$FILEPATH` env var, which V3 does not populate,
so the formatters were silently no-ops):

- `ruff-on-save` — Python (`\.py$`)
- `prettier-on-save` — JS/TS/CSS/HTML/JSON/MD/YAML
- `shfmt-on-save` — Shell (`\.sh$`)
- `swiftformat-on-save` — Swift (`\.swift$`)

## Backup (v2 JSON — DO NOT DELETE YET)

All original `.json` agent configs remain at `~/.kiro/agents/v2-backup/`.
The `~/.kiro/prompts/` directory is retained.
The `~/.kiro/agents/v3-preview/` directory is retained (now redundant — the real V3 agents
live in `~/.kiro/agents/*.md`; safe to delete once V3 is confirmed in production).

These can be removed once v3 is fully validated in production.

---

## Original Migration Mapping (Reference)

### 1. Agent config: JSON → Markdown + tags

V3 agents are Markdown files (`~/.kiro/agents/<name>.md`) with YAML frontmatter; the **body is the
system prompt** (so our `prompts/*.md` bodies fold into the agent file).

| v2 (JSON) | v3 (Markdown frontmatter) |
| --- | --- |
| `"tools": ["*"]` | `tools: ["*"]` — **quote the star**; bare `tools: [*]` is a YAML alias and fails to parse (or use specific tags) |
| explicit tool IDs / `@builtin` | **category tags**: `read`, `write`, `shell`, `web`, `subagent`, `knowledge`, `todo_list`, `@mcp`, `@builtin`, `*` |
| `"prompt": "file://~/.kiro/prompts/x.md"` | system prompt becomes the **document body** |
| `mcpServers` block | `mcpServers:` in frontmatter (inline, same shape; `${VAR}` env expansion) |
| `resources` (`file://`, `skill://`) | `resources:` (same URIs) |
| `toolsSettings.shell.deniedCommands` | `permissions:` with `{ capability: shell, effect: deny, match: [...] }` |
| `toolsSettings.web_fetch.trusted` | `permissions:` with `{ capability: web_fetch, effect: allow, match: [...] }` |
| `keyboardShortcut`, `welcomeMessage`, `description`, `model` | same keys in frontmatter |
| embedded `hooks` | standalone `.kiro/hooks/formatters.json` |

### 2. Hooks: embedded → standalone `.kiro/hooks/formatters.json`

Trigger name mapping:

| v2 | v3 |
| --- | --- |
| `postToolUse` | `PostToolUse` |
| `preToolUse` | `PreToolUse` |
| `agentSpawn` | `SessionStart` |
| `fileEdited` | `PostFileSave` |

### 3. Permissions

| v2 | v3 rule |
| --- | --- |
| `deniedCommands: ["git-defender.*"]` | `{ capability: shell, effect: deny, match: ["git-defender*"] }` |
| `shell.autoAllowReadonly: true` | default behavior in v3 |
| `web_fetch.trusted: [...]` | `{ capability: web_fetch, effect: allow, match: [...] }` |

### 4. Removed in v3

- `aws_tool` — removed; MCP servers only (we already use `aws-mcp-server`).
- Supervised mode — removed; use `permissions.yaml`.
- `--trust-all-tools` / `/tools trust` — replaced by `permissions.yaml`.

## V2 Retirement Plan (dual-format sunset)

The dual-format layout (`.md` + generated `.json`) doubles maintenance surface and exists only
because V3 is still early access. **Trigger to retire V2: the Kiro CLI changelog announces V3 is
GA / the default engine (no longer "early access").** When that happens:

1. Confirm on this machine: `kiro-cli chat` (no flag) uses the V3 engine, all 18+ agents load.
2. Delete the generated V2 artifacts: top-level `agents/*.json` and `prompts/*.md` (the bodies
   live in the `.md` agents; `prompts/ring.md` etc. are generated copies).
3. Delete `agents/v2-backup/` (pristine pre-migration backup, no longer needed).
4. Simplify `sync-agents.py` away (or keep `--check` as a frontmatter linter only) and remove
   `validate.sh` Steps 1.5/3.5 accordingly; drop the V2 rows from README.
5. Convert or delete the V2-only legacy agents (`stocks`, `shopify`, `reinvent`, `promptgen`)
   — they have no `.md` and will stop loading once V2 is gone.
6. Update README install prompt + this doc; bump CHANGELOG.

Until that trigger: edit `.md`, run `./sync-agents.py`, never hand-edit the generated `.json`.

## Migration Checklist

- [x] Convert `master` → `agents/master.md` (Markdown)
- [x] Convert all remaining agents (16 more)
- [x] Extract embedded hooks → `.kiro/hooks/formatters.json`
- [x] Re-express `toolsSettings` as agent `permissions:` blocks
- [x] Validate master.md AVAILABLE SUBAGENTS includes ios + ios-testing
- [x] ios-testing shortcut = shift+t (not ctrl+9)
- [x] Orchestrators (master, web-builder, ai-builder) have explicit subagent tag
- [x] `disabled: false` omitted from all mcpServers
- [x] Quote the star: `tools: ["*"]` (NOT bare `[*]`) — validated all 17 parse (2026-07-18)
- [x] Validate V3 frontmatter via `./validate.sh` (Step 1 parses Markdown agents)
- [ ] Smoke test: `kiro-cli chat --v3` — delegate to a subagent, verify a formatter hook fires
- [ ] Remove old JSON files from `agents/v2-backup/` (after V3 is confirmed in production)
