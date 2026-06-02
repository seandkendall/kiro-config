---
inclusion: auto
name: mcp-tool-discovery
description: How to discover and use MCP tools when you're unsure which one is configured. Triggers when an agent doesn't know whether an MCP tool exists for a task, or when a task description maps to multiple possible MCP servers.
---

# MCP Tool Discovery

When you need to perform an action and aren't sure whether an MCP tool exists for it, follow this discovery flow BEFORE shelling out to a CLI command.

## Decision Tree

```
Need to do X?
│
├─ 1. Is there a configured MCP server that obviously handles X?
│     (github → github MCP, AWS → aws-mcp-server, search → web-search, etc.)
│     YES → use it
│     NO  → continue
│
├─ 2. Use the `tool_search` tool to find matching MCP tools
│     `tool_search(query="<keywords>")`
│     Match found → use it
│     No match → continue
│
└─ 3. Fall back to a CLI command via shell
      (only if no MCP tool exists for the operation)
```

## Using `tool_search`

The `tool_search` tool loads MCP tool definitions on demand. It accepts either:

- `tool_id` (exact match in `server_name::tool_name` format) — when you know the exact tool
- `query` (keyword search) — when you're exploring

### Examples

```
# Looking for any GitHub tool
tool_search(query="github pull request")
→ returns: github::create_pull_request, github::get_pull_request, github::list_pull_requests, …

# Looking for browser automation
tool_search(query="browser screenshot")
→ returns: playwright::*, chrome-devtools::*, browser-lens::*

# Looking for AWS Cost Explorer
tool_search(query="aws cost")
→ returns: aws-mcp-server::call_aws (use for Cost Explorer + Pricing API)
```

After `tool_search` activates a matched tool, invoke it with **just the `tool_name`** (not the prefixed `server_name::tool_name`). For example, if the search returned `github::create_repository`, call `create_repository`, not `github::create_repository`.

## Common Mappings (Cheat Sheet)

| What you need                                     | MCP server                        | Example tool                        |
| ------------------------------------------------- | --------------------------------- | ----------------------------------- |
| Create a GitHub repo                              | `github`                          | `create_repository`                 |
| Read a file from GitHub                           | `github`                          | `get_file_contents`                 |
| Search code on GitHub                             | `github`                          | `search_code`                       |
| Make any AWS API call                             | `aws-mcp-server`                  | `call_aws`                          |
| Run sandboxed Python with AWS access              | `aws-mcp-server`                  | `run_script`                        |
| Search AWS docs                                   | `aws-mcp-server`                  | `search_documentation`              |
| Search the web                                    | `web-search`                      | `search`                            |
| Look up library docs (React, Vite, AWS SDK, etc.) | `context7`                        | `query-docs`                        |
| Browser automation / E2E                          | `playwright` or `chrome-devtools` | various                             |
| Inspect live CSS / Figma diff                     | `browser-lens`                    | various                             |
| Generate UI components from a description         | `21st-dev-magic`                  | `/ui ...`                           |
| Pull Figma layout                                 | `figma`                           | various                             |
| Read Google Docs/Sheets                           | `google-drive`                    | `search_files`, `read_file_content` |
| Generate an image                                 | `bedrock-image-mcp-server`        | `generate_image`                    |
| Sequential reasoning / planning                   | `sequentialthinking`              | `sequentialthinking`                |

## When to Fall Back to CLI

Only fall back to a CLI command when:

1. `tool_search` returns nothing
2. AND the configured MCP servers obviously don't cover this operation
3. AND the operation is genuinely necessary

Even then: prefer the AWS CLI shell tool over `gh`, `curl`, or other commands, since `aws` is more portable across machines.

## Anti-Patterns

❌ **Don't shell out to `gh` for github.com operations** — the `github` MCP server handles all of them
❌ **Don't use `curl` against AWS endpoints** — use `aws-mcp-server`
❌ **Don't use `web_fetch` against `docs.aws.amazon.com`** — use `aws___search_documentation`
❌ **Don't guess library API surfaces from training data** — use `context7` for live docs
❌ **Don't manually craft Playwright selectors for live debugging** — use `playwright` MCP's `generate_locator` tool, `browser-lens`, or `chrome-devtools`

If you find yourself reaching for a CLI when an MCP server is available, **stop and switch to the MCP tool**.
