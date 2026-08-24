---
inclusion: auto
name: aws-agent-toolkit
description: 'AWS MCP Server usage rules — prefer the managed MCP server, discover skills before acting, verify docs. Use when interacting with AWS services, APIs, or infrastructure.'
---

# AWS Agent Toolkit Rules

> **See also:** `mcp-server-preference.md` — the umbrella rule that requires MCP server usage over CLI commands across all configured MCP servers (GitHub, AWS, web search, etc.). This file is the AWS-specific deep-dive.

## MCP Server Usage

- Prefer the AWS MCP Server (`aws-mcp-server`) for AWS interactions over the `aws` CLI shell tool — it provides sandboxed execution, observability, and audit logging. Use the bare `aws` CLI only as a last-resort fallback when `aws-mcp-server` is unavailable.
- **Current tool set (verified against the live tool registry — re-check periodically, this server's tools evolve):**
  - `aws___run_script` — the primary tool for AWS API calls: sandboxed Python with `call_boto3()` access. Use for anything involving 2+ API calls, multi-region/multi-account work, analysis/comparison, diagnosis, or verification — not just single one-off calls.
  - `aws___call_aws` — **deprecated in favor of `aws___run_script`.** Only reach for it as a fallback if `run_script` genuinely can't express a one-off CLI-shaped command; prefer `run_script` by default.
  - `aws___search_documentation` — AWS docs search (topic filters: `reference_documentation`, `current_awareness`, `troubleshooting`, `cdk_docs`, `cdk_constructs`, `cloudformation`, `agent_skills`, `general`, and others). Prefer answering directly from the returned chunks over re-fetching.
  - `aws___read_documentation` — fetch full doc pages as markdown; only when `search_documentation`'s chunks genuinely lack the detail needed (e.g., enumerating a complete list).
  - `aws___retrieve_skill` — pulls a curated AWS skill (workflow/reference) by exact `skill_name` from a prior `search_documentation` (topic `agent_skills`) result. Never guess a skill name.
  - `aws___get_regional_availability` — check whether a product/API/CFN resource is available in specific regions.
  - `aws___get_presigned_url` — generate S3 pre-signed upload/download URLs (use before an operation that needs a local file path).
  - `aws___get_tasks` — poll long-running async operations started by other AWS MCP tools.
  - `aws___list_regions` — enumerate AWS regions.
- Before starting an AWS task, check whether a relevant AWS skill is available: `aws___search_documentation` with topic filter `agent_skills`, then load with `aws___retrieve_skill`.
- When uncertain about specific AWS details (API parameters, permissions, limits, error codes), verify against documentation using `aws___search_documentation` rather than guessing. State uncertainty explicitly if you cannot confirm.
- There is no dedicated "suggest AWS commands" tool as of this writing — for newly released services that may not be in training data, use `aws___search_documentation` (topic `current_awareness` or `reference_documentation`) instead.

## Infrastructure Preferences

- When creating infrastructure, prefer infrastructure-as-code (AWS CDK in Python) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework principles.
- For newly released services that may not be in training data, use `aws___search_documentation` (topic `current_awareness` or `reference_documentation`) to get correct current API syntax rather than guessing.
- For AgentCore Gateway work specifically: prefer the built-in **Connectors** (Web Search Tool, Amazon Bedrock Managed Knowledge Bases) over hand-rolled MCP servers, and prefer fronting an AgentCore Runtime agent with a Gateway (**AgentCore Runtime target**, aka "Agent target") over connecting to the Runtime endpoint directly. Full guidance, setup code, and IAM policies: `skills/amazon-bedrock/references/agentcore-gateway.md`.

## AWS Support API Guard

See `post-task-recommendations.md` → "AWS Support Case Ban (STRICT)" for the full rule (never open AWS Support or Service Quotas cases without explicit user instruction). Not repeated here to avoid drift between two copies of the same rule — if you land on this file looking for that rule, follow the link.
