---
inclusion: auto
name: aws-agent-toolkit
description: AWS MCP Server usage rules — prefer the managed MCP server, discover skills before acting, verify docs. Use when interacting with AWS services, APIs, or infrastructure.
---

# AWS Agent Toolkit Rules

> **See also:** `mcp-server-preference.md` — the umbrella rule that requires MCP server usage over CLI commands across all configured MCP servers (GitHub, AWS, web search, etc.). This file is the AWS-specific deep-dive.

## MCP Server Usage

- Prefer the AWS MCP Server (`aws-mcp-server`) for AWS interactions over the `aws` CLI shell tool — it provides sandboxed execution, observability, and audit logging. Use the bare `aws` CLI only as a last-resort fallback when `aws-mcp-server` is unavailable.
- Before starting an AWS task, check whether a relevant AWS skill is available. Use `aws___search_documentation` with topic filter `agent_skills` to discover skills, then load with `aws___retrieve_skill`.
- When uncertain about specific AWS details (API parameters, permissions, limits, error codes), verify against documentation using `aws___search_documentation` rather than guessing. State uncertainty explicitly if you cannot confirm.

## Infrastructure Preferences

- When creating infrastructure, prefer infrastructure-as-code (AWS CDK in Python) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework principles.
- Use `aws___suggest_aws_commands` to get correct API syntax for newly released services that may not be in training data.
