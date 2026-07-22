---
inclusion: auto
name: kiro-cli-troubleshooting
description: "Common Kiro CLI problems and fixes — missing tools, MCP server failures, agent validation errors, side-channel detection. Use when an agent, MCP server, or skill behaves unexpectedly."
---

# Kiro CLI Troubleshooting

Quick fixes for common issues with this Kiro CLI configuration.

## Agent Issues

### "No MCP server named 'X' found in any agent"

The agent config references an MCP server name that conflicts with Tool Search's deferred tool registration. Rename the server key in the agent's `mcpServers` block to use a different identifier (e.g., `sequentialthinking` instead of `sequential-thinking`).

### "Custom orchestrator agent silently fails to delegate"

Add `subagent` to the agent's `tools` array, or use `"tools": ["*"]` / `"@builtin"` to inherit all built-in tools. Without this, the agent can't spawn subagents.

### Agent validation fails: "File URI not found"

Prompt URIs must use `file://~/.kiro/prompts/<name>.md` (absolute home expansion) — NOT `file://./prompts/<name>.md` (relative, which the validator resolves against the agent file's parent directory).

### Kiro CLI V3: agents don't load / `kiro-cli --v3` shows only built-ins

If `kiro-cli chat --v3` can't find your agents (or `agent list` errors "user defined default `master` not found"):

- **Invalid YAML frontmatter.** Most common cause: `tools: [*]` (bare star) is a YAML alias and fails to parse, so V3 silently rejects the agent. Quote it: `tools: ["*"]`. Verify all agents with `./validate.sh` (Step 1 parses the Markdown frontmatter).
- **Wrong command.** V3 is `kiro-cli chat --v3` (or `kiro-cli chat --agent-engine v3`). The `kiro-cli agent list` / `agent validate` subcommands are **V2/JSON-only** — they report "master not found" and can't parse `.md` agents. That's expected, not the bug.
- **Agents in the wrong place.** Global V3 agents live in `~/.kiro/agents/*.md`; the agent name is the filename without extension (`master.md` → `master`).

## MCP Server Issues

### MCP server reports "command not found"

The MCP server requires a tool that isn't installed. Common dependencies:

| Tool                                   | Install                                            |
| -------------------------------------- | -------------------------------------------------- |
| `uv` / `uvx`                           | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `node` / `npx`                         | `brew install node`                                |
| `awsdac`                               | `brew install awsdac`                              |
| `awscli`                               | `brew install awscli`                              |
| `graphviz` (for `diagrams` Python lib) | `brew install graphviz`                            |

### MCP server requires API key

Check `~/.zshrc` for the env var. If not present, the server will fail at startup. Re-run `./import.sh` — the installer prompts for missing keys and offers to disable the MCP server if you skip.

### MCP server times out on first run

`uvx`/`npx` often download packages on first run (15-60s). Increase `mcp.noInteractiveTimeout` in `settings/cli.json` to `180000` (3 minutes) — already set in this config.

## Side Channel Issues (Kiro CLI 2.3.0+)

### `$AGENT_DISPLAY_OUT` is empty when running deploy.sh manually

Side channels are only set when Kiro CLI invokes the script. Wrappers should fall back gracefully:

```bash
DISPLAY_OUT="${AGENT_DISPLAY_OUT:-/dev/stderr}"
CONTEXT_OUT="${AGENT_CONTEXT_OUT:-/dev/null}"
```

This pattern is already used in `skills/deploy.sh.template`.

### Agent doesn't see deploy summary

Make sure your script writes summary lines to `$AGENT_CONTEXT_OUT` (captured as `agent_notes`), not just `$AGENT_DISPLAY_OUT` (TUI only).

## Settings Issues

### Default agent doesn't switch to master

Run: `kiro-cli settings chat.defaultAgent '"master"'` (note the nested quotes for JSON string values).

### Skills don't appear as slash commands

Skills as slash commands require Kiro CLI 2.1+. Verify with `kiro-cli --version`. Also confirm the skill file has YAML frontmatter with `name` and `description`.

## Code Defender / Git Push Blocked

Some pushes get blocked by Code Defender. Approve manually in the prompt — the commit is local until you push successfully. **Never run `git-defender` commands** — they're explicitly blocked in every agent's `deniedCommands`.

## Kiro CLI V3 Runtime Errors

### `Invalid additionalModelRequestFields: property 'reasoning' is not defined in the schema`

`BedrockValidationError … property 'reasoning' … schema does not allow additional properties`.

- **Cause:** `chat.enableThinking: true` makes Kiro attach a `reasoning` field to the model request, but the **currently selected model doesn't support reasoning/thinking**. This happens after switching the active model with `/model` to a non-reasoning model (e.g., `gpt-5.6-sol`). The config default (`claude-opus-4.8`) supports reasoning, so it does not occur on the default.
- **Fix:** either switch back to a reasoning-capable model — `/model claude-opus-4.8` (persists) — OR turn thinking off for that model: `kiro-cli settings chat.enableThinking false` (or `/settings` → Display → Show thinking).
- Likely a Kiro V3 gap (it should strip `reasoning` for models that don't declare `reasoning.effort`) — worth reporting. Not a fault in the agent config.

### Other frequent V3 errors (mostly transient / not config)

- `[Remote tool web_search] Tool call failed: Tool returned no results` / `Invalid tool parameters` — the built-in web_search remote tool; retry or rephrase. Not a config issue.
- `Failed to stream response chunks (inputSize≈1,000,000+, historyMessages=100+)` — very large context on long sessions. Mitigate with `/compact`, start a fresh session (`/chat new`), avoid reading huge files wholesale, or set `chat.disableInheritingDefaultResources` for lean custom agents.
- `[tool-call-emitter] Location.path must be absolute. Got relative path` — the model passed a relative path to a file tool; benign, auto-retries with the absolute path.
- `InternalServerException` / `ServerConnectionResetError: aborted` — transient, **server-side, retryable** Bedrock/network errors; retry (Kiro retries automatically). More likely on very large payloads — observed at `inputSize=772524, historyMessages=142` (~772 KB). If it recurs, shrink context: `/compact` or `/chat new`. Contributing config factor: every agent lists `file://~/.kiro/steering/*.md` in `resources` while V3 (≥2.7) also auto-inherits default steering — this can double-load steering. To de-dupe, set `chat.disableInheritingDefaultResources: true` (or drop the explicit steering glob from agent `resources`).
- `Failed to connect … creds-agent (Connection closed)` — a machine-local MCP (`aim mcp start-server`), not part of this repo; safe to ignore or remove from your agent's `mcpServers` if unused.

## Diagnostic Commands

```bash
kiro-cli --version                    # Confirm version (2.10.0+ tested; 2.3.0 min for side channels)
kiro-cli mcp list                     # See all MCP servers and their status
kiro-cli agent list                   # List configured agents
kiro-cli agent validate --path <file> # Validate an agent config
kiro-cli settings list                # Dump all settings
kiro-cli doctor                       # Run built-in diagnostics
```
