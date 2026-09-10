---
inclusion: auto
name: aws-agent-toolkit
description: 'AWS MCP Server usage rules — prefer the managed MCP server, discover skills before acting, verify docs. Use when interacting with AWS services, APIs, or infrastructure.'
---

# AWS Agent Toolkit Rules

> **See also:** `mcp-server-preference.md` — the umbrella rule that requires MCP server usage over CLI commands across all configured MCP servers (GitHub, AWS, web search, etc.). This file is the AWS-specific deep-dive.

## MCP Server Usage

- Prefer the AWS MCP Server (`aws-mcp-server`) for AWS interactions over the `aws` CLI shell tool — it provides sandboxed execution, observability, and audit logging. Use the bare `aws` CLI only as a last-resort fallback when `aws-mcp-server` is unavailable.
- **Tool names below are NOT guaranteed literal, callable strings — treat them as identifiers to discover, not to hardcode.** The AWS MCP Server's actual tools show up under different names depending on how the runtime registers them in a given session (e.g. `aws___search_documentation` vs. `mcp_aws_mcp_server_aws___search_documentation`), and calling either form blind can fail with `Tool "X" is not available` even when the capability exists. Always resolve the real callable name via `tool_search` first — see "Resolving the correct tool name" below — rather than typing one of the names in this list directly into a tool call.
- **Current tool set (verified against the live tool registry — re-check periodically, this server's tools evolve):**
  - `run_script` (search as `aws___run_script`) — the primary tool for AWS API calls: sandboxed Python with `call_boto3()` access. Use for anything involving 2+ API calls, multi-region/multi-account work, analysis/comparison, diagnosis, or verification — not just single one-off calls.
  - `call_aws` (search as `aws___call_aws`) — **deprecated in favor of `run_script`.** Only reach for it as a fallback if `run_script` genuinely can't express a one-off CLI-shaped command; prefer `run_script` by default.
  - `search_documentation` (search as `aws___search_documentation`) — AWS docs search (topic filters: `reference_documentation`, `current_awareness`, `troubleshooting`, `cdk_docs`, `cdk_constructs`, `cloudformation`, `agent_skills`, `general`, and others). Prefer answering directly from the returned chunks over re-fetching.
  - `read_documentation` (search as `aws___read_documentation`) — fetch full doc pages as markdown; only when `search_documentation`'s chunks genuinely lack the detail needed (e.g., enumerating a complete list).
  - `retrieve_skill` (search as `aws___retrieve_skill`) — pulls a curated AWS skill (workflow/reference) by exact `skill_name` from a prior `search_documentation` (topic `agent_skills`) result. Never guess a skill name.
  - `get_regional_availability` (search as `aws___get_regional_availability`) — check whether a product/API/CFN resource is available in specific regions.
  - `get_presigned_url` (search as `aws___get_presigned_url`) — generate S3 pre-signed upload/download URLs (use before an operation that needs a local file path).
  - `get_tasks` (search as `aws___get_tasks`) — poll long-running async operations started by other AWS MCP tools.
  - `list_regions` (search as `aws___list_regions`) — enumerate AWS regions.
- Before starting an AWS task, check whether a relevant AWS skill is available: resolve and call the AWS docs-search tool with topic filter `agent_skills`, then load with the retrieve-skill tool (see "Resolving the correct tool name").
- When uncertain about specific AWS details (API parameters, permissions, limits, error codes), verify against documentation using the AWS docs-search tool rather than guessing. State uncertainty explicitly if you cannot confirm.
- There is no dedicated "suggest AWS commands" tool as of this writing — for newly released services that may not be in training data, use the AWS docs-search tool (topic `current_awareness` or `reference_documentation`) instead.

## Resolving the correct tool name (MANDATORY — prevents "Tool is not available" errors)

If a call to any AWS MCP tool fails with `Tool "X" is not available` (whichever literal name `X` was tried — bare `aws___...` or fully-qualified `mcp_aws_mcp_server_aws___...`), do NOT retry the same literal string, and do NOT silently give up or fall back to guessing. Instead:

1. Call `tool_search` with `tool_id: "aws-mcp-server::<tool_name>"` (the bare name, e.g. `aws-mcp-server::aws___search_documentation`) OR `query: "<keywords>"` if unsure of the exact tool.
2. `tool_search`'s response loads the tool and confirms it exists — use exactly the invocation path it makes available next (this may be the bare name, or a fully-qualified `mcp_<server>_<tool>` form depending on the runtime). Do not assume which form will work before trying it.
3. If the tool_search-confirmed name ALSO fails with "not available," try the other naming convention once (bare `aws___x` vs. fully-qualified `mcp_aws_mcp_server_aws___x`) before concluding the server itself is unreachable.
4. If both forms fail, verify the MCP server is actually running/connected (e.g. call a trivial tool like `list_regions` in the same way) before reporting the capability as broken — a single tool failing while others succeed usually means a naming issue, not a dead server.
5. Never fabricate a workaround (e.g., answering from training data as if verified, or inventing a CLI equivalent) just because a specific tool name didn't resolve — retry via discovery first.

This applies to every tool listed above, not just `search_documentation` — the naming instability is a property of the MCP runtime, not any one tool.

## Infrastructure Preferences

- When creating infrastructure, prefer infrastructure-as-code (AWS CDK in Python) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework principles.
- For newly released services that may not be in training data, use the AWS docs-search tool (topic `current_awareness` or `reference_documentation`) to get correct current API syntax rather than guessing.
- For AgentCore Gateway work specifically: prefer the built-in **Connectors** (Web Search Tool, Amazon Bedrock Managed Knowledge Bases) over hand-rolled MCP servers, and prefer fronting an AgentCore Runtime agent with a Gateway (**AgentCore Runtime target**, aka "Agent target") over connecting to the Runtime endpoint directly. Full guidance, setup code, and IAM policies: `skills/amazon-bedrock/references/agentcore-gateway.md`.

## AWS Support API Guard

See `post-task-recommendations.md` → "AWS Support Case Ban (STRICT)" for the full rule (never open AWS Support or Service Quotas cases without explicit user instruction). Not repeated here to avoid drift between two copies of the same rule — if you land on this file looking for that rule, follow the link.
