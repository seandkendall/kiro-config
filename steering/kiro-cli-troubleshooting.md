---
inclusion: auto
name: kiro-cli-troubleshooting
description: Common Kiro CLI problems and fixes — missing tools, MCP server failures, agent validation errors, side-channel detection. Use when an agent, MCP server, or skill behaves unexpectedly.
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

## Diagnostic Commands

```bash
kiro-cli --version                    # Confirm version (2.8.0+ tested; 2.3.0 min for side channels)
kiro-cli mcp list                     # See all MCP servers and their status
kiro-cli agent list                   # List configured agents
kiro-cli agent validate --path <file> # Validate an agent config
kiro-cli settings list                # Dump all settings
kiro-cli doctor                       # Run built-in diagnostics
```
