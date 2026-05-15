---
inclusion: always
name: AGENTS
description: Multi-agent orchestration architecture, master/subagent ecosystem, delegation rules, subagent vs delegate semantics, Kiro CLI 2.3.0+ features. Use when building or routing across agents.
---

# AGENTS.md

## Agent Ecosystem Overview

This workspace uses a multi-agent architecture with a master orchestrator and specialized subagents.

## When to Use Which Agent

- **`/agent master`** (ctrl+1) — Default. Routes to the right specialist.
- **`/agent accounting`** (ctrl+3) — Canadian accounting SaaS (Wave/QuickBooks alternative, Alberta-focused)
- **`/agent serverless`** (ctrl+4) — AWS Lambda, API Gateway, DynamoDB, Powertools, X-Ray
- **`/agent frontend`** (ctrl+5) — React, TypeScript, Tailwind CSS, shadcn/ui components
- **`/agent testing`** (ctrl+6) — pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent
- **`/agent research`** — Deep research on any topic with web search and docs

## Available Subagents

Builder agents automatically delegate to these specialists:

| Subagent     | Specialty                                                             |
| ------------ | --------------------------------------------------------------------- |
| `serverless` | Lambda, API GW, DynamoDB, Step Functions, Powertools, X-Ray           |
| `frontend`   | React, TypeScript, Tailwind, shadcn/ui, accessibility                 |
| `testing`    | pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent        |
| `cypress`    | Cypress E2E tests, Page Objects, 100% coverage target                 |
| `architect`  | Architecture diagrams, cost estimation, Well-Architected reviews      |
| `ai-builder` | Bedrock, Strands Agents, prompt engineering, RAG                      |
| `devops`     | CloudWatch monitoring, alerting, cost optimization, incident response |
| `data`       | DynamoDB single-table design, Postgres, data modeling                 |
| `security`   | IAM, encryption, cdk-nag, CloudTrail, Well-Architected Security       |
| `docs`       | READMEs, API docs, ADRs, auto-generated code docs                     |
| `image-gen`  | Image generation via Bedrock Image — Nova Canvas + SD 3.5             |
| `research`   | Web search, AWS docs, GitHub, library docs                            |
| `sap-abap`   | SAP ABAP — Clean ABAP, ALV, BAPIs, data migration, CDS, RAP           |

## Delegation Rules

- Up to 4 subagents can run in parallel
- Subagents cannot communicate with each other — only report back to the parent
- Use @path syntax to reference files inline — saves tool calls and tokens

## `ai-builder` vs `agentcore` — Which to Pick

Both touch AWS Bedrock and Strands Agents, but they're scoped differently:

| Agent            | Use when                                                                                                                                                                                                                              | Don't use when                                                  |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **`ai-builder`** | You need AI integration patterns: model selection (Sonnet vs Haiku vs Nova), prompt engineering, RAG architecture, Converse API + guardrails, streaming + retry patterns, batch inference. Specialist.                                | You want to build a complete deployed AgentCore app end-to-end. |
| **`agentcore`**  | You're building, deploying, or testing a full AWS AgentCore application with Strands Agents — frontend (React) + backend (Lambda + AgentCore runtime) + memory + gateway + observability. Orchestrator with full subagent delegation. | You just need help picking a Bedrock model or writing a prompt. |

If unsure: start with `ai-builder` for design questions, switch to `agentcore` when you're ready to scaffold the full app.

## `subagent` vs `delegate` — Which Tool to Use

Both tools spawn separate work streams, but they have different semantics. Pick the right one:

| Tool                                  | Semantics                                                                                                                                    | When to use                                                                                                                                                                     |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`subagent`** (alias `use_subagent`) | **Synchronous**, parallel, isolated context. Up to 4 at once. Returns results to parent. Configurable via `availableAgents`/`trustedAgents`. | DEFAULT. Use whenever the parent needs the result to continue (orchestration, parallel research, multi-step pipelines). This is the master agent's primary tool.                |
| **`delegate`**                        | **Asynchronous** background task. No config. Check status with `/delegate status`.                                                           | NICHE. Only for long-running work where the user keeps doing other things in the foreground (e.g., "scan the entire monorepo for unused exports while I work on this feature"). |

If unsure, use `subagent`. Never use `delegate` just because the task is long — use it only when the result genuinely doesn't need to be in-band with the current conversation.

> **Custom orchestrator agents must declare the `subagent` tool.** If you build a new agent that needs to spawn subagents, include `subagent` in its `tools` array (or use `"tools": ["*"]` / `"@builtin"` to inherit all built-ins). Without it, the agent silently fails to delegate. Agents currently configured for delegation: `master`, `accounting`.

## Kiro CLI 2.3.0 Features Worth Knowing

- **Agent output side channels** — `$AGENT_DISPLAY_OUT` and `$AGENT_CONTEXT_OUT` env vars in shell commands route verbose output to the user TUI without polluting agent context (used by `deploy.sh`)
- **OAuth Client ID for HTTP MCP servers** — set `oauth.clientId` in MCP config to use Slack/GitHub/Figma HTTP MCP servers without DCR (we don't need this — our MCPs are stdio)
- **`KIRO_HOME` env var** — relocate the global config directory if needed
- **Configurable V2 TUI keybindings** — remap Ctrl+C / Esc / quit if they conflict with tmux

## Adaptive Thinking (Kiro CLI 2.2+)

Claude Opus 4.7 with adaptive thinking is the default model. Reasoning automatically scales with task complexity and persists across multi-turn conversations. Keep `chat.enableThinking = true` (already set).
