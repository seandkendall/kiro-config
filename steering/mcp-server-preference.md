---
inclusion: always
name: mcp-server-preference
description: 'Enforce MCP server usage over equivalent CLI commands. Prevents agents from shelling out to gh, aws, etc. when an MCP server provides the same capability.'
---

# MCP Server Preference (MANDATORY)

When a configured MCP server provides a capability, **use the MCP server — do not shell out to a CLI**. MCP servers give the agent structured tool definitions, observability, IAM/audit context, and proper error handling. CLI commands bypass all of that.

## Hard Rules

### GitHub Operations — ALWAYS Use the `github` MCP Server

For ANY GitHub operation, use the `github` MCP server. Do NOT run `gh` CLI commands.

| What you need to do               | Use this MCP tool                                                          | Do NOT use                                       |
| --------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------ |
| Create a repo                     | `@github/create_repository`                                                | `gh repo create`                                 |
| Create a branch                   | `@github/create_branch`                                                    | `git push -u origin new-branch` (then API)       |
| Create/update a file              | `@github/create_or_update_file`                                            | `gh api repos/.../contents/...`                  |
| Push multiple files in one commit | `@github/push_files`                                                       | `git push` after `git commit`                    |
| Open a PR                         | `@github/create_pull_request`                                              | `gh pr create`                                   |
| Review a PR                       | `@github/create_pull_request_review`                                       | `gh pr review`                                   |
| Comment on a PR                   | `@github/get_pull_request_comments` + `@github/create_pull_request_review` | `gh pr comment`                                  |
| Get PR status                     | `@github/get_pull_request_status`                                          | `gh pr checks`                                   |
| Merge a PR                        | `@github/merge_pull_request`                                               | `gh pr merge`                                    |
| List/get issues                   | `@github/list_issues` / `@github/get_issue`                                | `gh issue list` / `gh issue view`                |
| Create/update issues              | `@github/create_issue` / `@github/update_issue`                            | `gh issue create`                                |
| Comment on an issue               | `@github/add_issue_comment`                                                | `gh issue comment`                               |
| Search code/repos/issues/users    | `@github/search_*`                                                         | `gh search ...`                                  |
| Read file contents                | `@github/get_file_contents`                                                | `gh api ...` or `curl raw.githubusercontent.com` |
| Fork a repo                       | `@github/fork_repository`                                                  | `gh repo fork`                                   |
| List commits on a branch          | `@github/list_commits`                                                     | `gh api repos/.../commits`                       |

**Why:** the `github` MCP server uses your `GITHUB_PERSONAL_ACCESS_TOKEN` directly with proper scopes, returns structured JSON the agent can parse reliably, and stays consistent across sessions. The `gh` CLI requires a separate `gh auth login`, varies in availability across machines, and emits free-form text that's harder to parse.

**Local git operations are still fine via shell** — `git status`, `git diff`, `git log`, `git add`, `git commit`, and `git push` to an already-configured remote. The MCP server is for **GitHub API operations** (repos, PRs, issues, branches, file contents). When in doubt: if it would touch github.com, use the MCP server.

### AWS Operations — ALWAYS Use the `aws-mcp-server` MCP Server

For AWS API calls, prefer `aws-mcp-server` (Agent Toolkit for AWS) over the `aws` CLI shell tool.

- Use `aws___run_script` (sandboxed Python + `call_boto3()`) for most AWS API calls — prefer it over `aws___call_aws`, which is now deprecated in favor of `run_script`, and over chaining `aws` CLI shell commands
- Use `aws___search_documentation` instead of `web_fetch` against `docs.aws.amazon.com`
- Use `aws___retrieve_skill` to load curated guidance instead of guessing API patterns

The built-in `aws` shell tool is acceptable as a fallback when `aws-mcp-server` isn't available, but it should NOT be the first choice.

### Other MCP Servers

The same rule applies to every configured MCP server:

| Capability               | Prefer                                      | Over                                |
| ------------------------ | ------------------------------------------- | ----------------------------------- |
| Library docs             | `@context7/...`                             | Guessing from training data         |
| Browser automation       | `@playwright/...` or `@chrome-devtools/...` | `curl` against the URL              |
| Component installation   | `@shadcn/...`                               | `npm install @radix-ui/*` manually  |
| Figma design data        | `@figma/...`                                | `web_fetch` against figma.com       |
| Google Drive/Docs/Sheets | `@google-drive/...` (read-only)             | `web_fetch` against docs.google.com |
| Image generation         | `@bedrock-image-mcp-server/...`             | Asking the user to find an image    |

**No longer needed as MCP servers — now built into Kiro CLI directly, use the built-in tool instead:**

- **Web search** — `web_search` is a built-in Kiro CLI tool (since 1.21; confirmed still built-in at 2.19.x). Do NOT add a DuckDuckGo (or any other) web-search MCP server — it duplicates a capability the agent already has natively and costs unnecessary MCP context/tokens for zero benefit.
- **Web page fetching** — `web_fetch` is likewise built-in. Don't configure a separate "fetch" MCP server for the same job.
- **Code intelligence** (symbol search, document outlines, definitions) — Tree-sitter-based code intelligence across 18 languages (Bash, C, C++, C#, Elixir, Go, Java, JavaScript, Kotlin, Lua, PHP, Python, Ruby, Rust, Scala, Swift, TSX, TypeScript) is built in via the `code` tool. Don't add a separate code-intelligence/LSP MCP server for languages already on that list.
- **Sequential reasoning** — the built-in thinking/reasoning capability covers most cases now; only add a dedicated sequential-thinking MCP server if a specific workflow needs its structured multi-step output. If one is configured, prefer it over sprawling inline reasoning blocks (`@sequentialthinking/sequentialthinking` over long inline reasoning).

**Rule of thumb going forward:** before adding any new MCP server, check whether Kiro CLI has since absorbed that capability natively — the unified agent harness (CLI 3.0+) ships new built-in tools regularly, and each one absorbed removes a server you no longer need to maintain, configure API keys for, or pay a context-token tax on.

## Discovery

If an agent isn't sure whether an MCP server is configured for a task:

1. Look at the tool list (it shows all available MCP tools when the agent is loaded)
2. Use `tool_search` with a relevant query (e.g., `tool_search query="github pr"`) to find matching MCP tools
3. Only fall back to a CLI command if no matching MCP tool exists

## Why This Matters

- **Reliability** — MCP tools return structured data; CLI output formats change between versions and break parsing
- **Auth consistency** — MCP servers use env-var-based credentials configured once in `~/.zshrc`, not separate per-CLI auth flows
- **Audit trail** — MCP calls are logged by Kiro CLI's tool tracking; arbitrary shell commands aren't categorized
- **Cross-machine portability** — the `github` MCP server works the same on your laptop, in CI, or on a fresh dev machine; `gh` CLI may not even be installed

If you find yourself reaching for a CLI when an MCP server is available, stop and switch to the MCP tool.
