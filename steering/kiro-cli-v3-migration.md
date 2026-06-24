---
inclusion: manual
name: kiro-cli-v3-migration
description: v2 -> v3 migration mapping for this Kiro config. Manual inclusion — pull in only when planning or executing the Kiro CLI V3 migration. Covers agent JSON -> Markdown+tags, embedded hooks -> standalone .kiro/hooks/*.json, toolsSettings -> permissions, and a migration checklist.
---

# Kiro CLI v2 → v3 Migration Mapping

> **Status: planning only.** This config runs on Kiro CLI **2.x**. V3 (shipped as early
> access in CLI 2.8.0, Jun 17 2026) is opt-in via `kiro-cli --v3` and runs alongside 2.x.
> Do NOT migrate until the official AWS v2→v3 migration guide lands ("coming soon"). This doc
> is the local mapping so we're ready. Prototype lives at `agents/v3-preview/master.md`.

## Why wait

- Official migration guide not yet published.
- V3 sessions are **not backward-compatible** (back up `~/.kiro/sessions/` before opting in).
- V3 does **not** support Amazon Linux 2 or classic (non-TUI) mode.
- Early access — APIs may still shift.

## Pre-flight (when we do migrate)

1. Back up `~/.kiro/sessions/`.
2. Run `kiro-cli diagnostic` to validate the V3 environment.
3. Migrate ONE agent first (`master`), validate, then roll out the rest.
4. `kiro-cli agent migrate` auto-converts embedded hooks to the standalone format.

## 1. Agent config: JSON → Markdown + tags

V3 agents are Markdown files (`~/.kiro/agents/<name>.md`) with YAML frontmatter; the **body is the
system prompt** (so our `prompts/*.md` bodies fold into the agent file, or stay referenced).

| v2 (our JSON today)                                          | v3 (Markdown frontmatter)                                                                                         |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `"tools": ["*"]`                                             | `tools: [*]` (or specific tags)                                                                                   |
| explicit tool IDs / `@builtin`                               | **category tags**: `read`, `write`, `shell`, `web`, `subagent`, `knowledge`, `todo_list`, `@mcp`, `@builtin`, `*` |
| `"prompt": "file://~/.kiro/prompts/x.md"`                    | system prompt becomes the **document body**                                                                       |
| `mcpServers` block                                           | `mcpServers:` in frontmatter (inline, same shape; `${VAR}` env expansion; `timeout`/`requestTimeout`)             |
| `resources` (`file://`, `skill://`)                          | `resources:` (same URIs)                                                                                          |
| `toolsSettings.subagent.availableAgents/trustedAgents`       | (subagent access via `subagent` tag + `permissions`)                                                              |
| `toolsSettings.shell` / `web_fetch` trust                    | `permissions:` block (see §3)                                                                                     |
| `keyboardShortcut`, `welcomeMessage`, `description`, `model` | same keys in frontmatter                                                                                          |
| embedded `hooks`                                             | move to standalone `.kiro/hooks/*.json` (see §2)                                                                  |

Tag mapping for our agents: most use `tools: ["*"]` → `tools: [*]`. Orchestrators (`master`,
`web-builder`, `ai-builder`) need the `subagent` tag. Add `@mcp` to expose all configured MCP tools.

## 2. Hooks: embedded → standalone `.kiro/hooks/*.json`

Our agents embed `postToolUse` prettier/shfmt/ruff formatters. In V3 these become standalone
files with a versioned schema and **PascalCase** triggers.

Trigger name mapping:

| v2                 | v3                 |
| ------------------ | ------------------ |
| `agentSpawn`       | `SessionStart`     |
| `userPromptSubmit` | `UserPromptSubmit` |
| `preToolUse`       | `PreToolUse`       |
| `postToolUse`      | `PostToolUse`      |
| `fileEdited`       | `PostFileSave`     |
| `fileCreated`      | `PostFileCreate`   |
| `stop`             | `Stop`             |

New triggers in 3.0: `PreTaskExec`, `PostTaskExec`, `PostFileDelete`, `Manual`. Two action types:
`{"type":"command","command":"..."}` and `{"type":"agent","prompt":"..."}`. Example for our formatter hook:

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "prettier-on-write",
      "trigger": "PostToolUse",
      "matcher": "fs_write",
      "action": {
        "type": "command",
        "command": "npx prettier --write \"$FILEPATH\" 2>/dev/null || true"
      }
    }
  ]
}
```

`kiro-cli agent migrate` will auto-convert the embedded hooks; review the output.

## 3. Permissions: toolsSettings / trust → capability rules

Two homes for permissions in V3:

- **Agent profile `permissions:` block** (version-controlled, repo-shareable) — put our intent here
  (e.g., allow `git *`/`npm *`, deny `git-defender.*`, deny reads of `.env`/secrets).
- **`permissions.yaml`** (user scope `~/.kiro/settings/permissions.yaml`, workspace scope
  `~/.kiro/workspace-roots/<hash>/permissions.yaml`) — **machine-local, per-user, OUTSIDE the repo.**
  A cloned repo cannot inject these. This file stays **gitignored permanently**.

Rule shape: `capability` (`fs_read`, `fs_write`, `filesystem`, `shell`, `web_fetch`, `web_search`,
`mcp`, `subagent`, `skill`, `diagnostics`, `context`, `all`, `builtin`) + `match` (globs) +
optional `exclude` + `effect` (`deny` > `ask` > `allow`). Compound shell commands are split and
evaluated per sub-command.

Mapping our current settings:

| v2                                                     | v3 rule                                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `deniedCommands: ["git-defender.*"]`                   | `{ capability: shell, effect: deny, match: ["git-defender*"] }`                             |
| `shell.autoAllowReadonly: true`                        | covered by default policy (read-only git/system info auto-allowed)                          |
| `web_fetch.trusted: [docs.aws.amazon.com, github.com]` | `{ capability: web_fetch, effect: allow, match: ["*docs.aws.amazon.com*","*github.com*"] }` |
| `--trust-all-tools` (CI)                               | `permissions.yaml` with `{ capability: all, effect: allow }`                                |

## 4. Removed in v3 (no action beyond awareness)

- `aws_tool` — removed; MCP servers only (we already prefer `aws-mcp-server`).
- Supervised mode — removed; use `permissions.yaml`.
- `--trust-all-tools` / `/tools trust` — replaced by `permissions.yaml`.

## 5. Migration checklist

- [ ] Official migration guide published + read
- [ ] Back up `~/.kiro/sessions/`
- [ ] `kiro-cli diagnostic` passes on target machine
- [ ] Convert `master` → `agents/v3-preview/master.md` is promoted to `agents/master.md` (Markdown)
- [ ] `kiro-cli agent migrate` to convert embedded hooks → `.kiro/hooks/*.json`
- [ ] Re-express `toolsSettings` as agent `permissions:` blocks
- [ ] Validate with `kiro-cli diagnostic` + a smoke test (delegate to a subagent, run a formatter hook)
- [ ] Roll out remaining agents
- [ ] Update `validate.sh` to validate V3 Markdown agents + standalone hooks
- [ ] Confirm `settings/permissions.yaml` remains gitignored
