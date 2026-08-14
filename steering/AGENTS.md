---
inclusion: always
name: AGENTS
description: 'Multi-agent orchestration architecture, master/subagent ecosystem, delegation rules, subagent vs delegate semantics, subagent review loops, Kiro CLI 2.13.0+ features. Use when building or routing across agents.'
---

# AGENTS.md

## Agent Ecosystem Overview

This workspace uses a multi-agent architecture with a master orchestrator and specialized subagents.

## When to Use Which Agent

- **`/agent master`** (ctrl+1) — Default. Routes to the right specialist.
- **`/agent master-demo`** (shift+m) — Single-agent demo for serverless backends. No subagents, only `aws-mcp-server`. Always CORS, never UI/WAF/Route53. Use for live demos.
- **`/agent serverless`** (ctrl+4) — AWS Lambda, API Gateway, DynamoDB, Powertools, X-Ray
- **`/agent ios`** (ctrl+7) — Native iOS: Swift, SwiftUI, CarPlay, MapKit, AVFoundation, MusicKit, offline-first
- **`/agent ios-testing`** (ctrl+9) — iOS tests: XCTest, XCUITest, snapshot tests, performance tests
- **`/agent frontend`** (ctrl+5) — React, TypeScript, Tailwind CSS, shadcn/ui components
- **`/agent testing`** (ctrl+6) — pytest, Jest/Vitest, Playwright E2E (data-testid selectors, Page Objects, 100% coverage target)
- **`/agent research`** — Deep research on any topic with web search and docs

## Available Subagents

Builder agents automatically delegate to these specialists:

| Subagent           | Specialty                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `serverless`       | Lambda, API GW, DynamoDB, Step Functions, Powertools, X-Ray                                                      |
| `frontend`         | React, TypeScript, Tailwind, shadcn/ui, accessibility                                                            |
| `testing`          | pytest, Jest/Vitest, Playwright E2E (data-testid selectors, Page Objects, 100% coverage target)                  |
| `architect`        | Architecture diagrams, cost estimation, Well-Architected reviews                                                 |
| `ios`              | Native iOS: Swift 5.9+, SwiftUI, CarPlay, MapKit, AVFoundation, MusicKit, CoreLocation, offline-first MVVM       |
| `ios-testing`      | XCTest unit tests, XCUITest UI automation, swift-snapshot-testing, performance tests                             |
| `ai-builder`       | Bedrock, Strands Agents, prompt engineering, RAG                                                                 |
| `devops`           | CloudWatch monitoring, alerting, cost optimization, incident response                                            |
| `data`             | DynamoDB single-table design, Postgres, data modeling                                                            |
| `security`         | IAM, encryption, cdk-nag, CloudTrail, Well-Architected Security                                                  |
| `docs`             | READMEs, API docs, ADRs, auto-generated code docs                                                                |
| `image-gen`        | Image generation via Bedrock Image — Nova Canvas + SD 3.5                                                        |
| `research`         | Web search, AWS docs, GitHub, library docs                                                                       |
| `web-builder`      | React + AWS full-stack web apps; itself orchestrates frontend/serverless/ai-builder when scaffolding entire apps |
| `google-workspace` | Google Docs, Sheets, Drive (read-only)                                                                           |

## Delegation Rules

- Up to 4 subagents can run in parallel
- Subagents cannot communicate with each other — only report back to the parent
- Use @path syntax to reference files inline — saves tool calls and tokens
- **Orchestrators can call other orchestrators.** `master` delegates to `web-builder` for full-stack web app scaffolds and to `ai-builder` for full agentic apps. `web-builder` delegates to `ai-builder` when an app needs AI features. `ai-builder` delegates to `web-builder`'s subagents (frontend, serverless) for the surrounding app shell. Orchestrator-to-orchestrator calls are useful when one orchestrator's scope nests inside another's task — keep the chain shallow (max 2 hops) to avoid context fragmentation.
- **Subagent review loops (Kiro CLI 2.5.0+).** A subagent pipeline can now self-correct: a reviewer stage sends work back to the implementer stage and loops until the work meets the bar, all before results return to the parent. Use this for review/refactor workflows — e.g., `serverless` implements → `security` reviews → loops back to `serverless` if cdk-nag findings remain. Set a `loop_to` target with a `trigger` phrase and a `max_iterations` cap (so a failing reviewer can't loop forever). Prefer a bounded loop over manually re-spawning the implementer.

## Subagent Review Loops

When a multi-agent pipeline benefits from a quality gate, wire a reviewer stage that can bounce work back:

- The reviewer emits a trigger phrase (e.g., `NEEDS_CHANGES`) when the work isn't acceptable
- That trigger loops the task back to the implementer stage with the reviewer's feedback as context
- A `max_iterations` cap stops the loop even if the bar is never met (surfaces the impasse instead of spinning)

Good fits in this config:

- **Code review**: `serverless`/`frontend` implements → `security` or `testing` reviews → loops back on failures until cdk-nag/lint/tests pass
- **Refactor**: implementer refactors → reviewer checks behavior preserved → loops until clean
- **Docs accuracy**: `docs` drafts → `research` verifies claims → loops on unverified statements

Keep `max_iterations` low (2–3) for demos and tight for production so a stuck reviewer fails loud rather than burning the budget.

## `subagent` vs `delegate` — Which Tool to Use

Both tools spawn separate work streams, but they have different semantics. Pick the right one:

| Tool                                  | Semantics                                                                                                                                    | When to use                                                                                                                                                                     |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`subagent`** (alias `use_subagent`) | **Synchronous**, parallel, isolated context. Up to 4 at once. Returns results to parent. Configurable via `availableAgents`/`trustedAgents`. | DEFAULT. Use whenever the parent needs the result to continue (orchestration, parallel research, multi-step pipelines). This is the master agent's primary tool.                |
| **`delegate`**                        | **Asynchronous** background task. No config. Check status with `/delegate status`.                                                           | NICHE. Only for long-running work where the user keeps doing other things in the foreground (e.g., "scan the entire monorepo for unused exports while I work on this feature"). |

If unsure, use `subagent`. Never use `delegate` just because the task is long — use it only when the result genuinely doesn't need to be in-band with the current conversation.

> **Custom orchestrator agents must declare the `subagent` tool.** If you build a new agent that needs to spawn subagents, include `subagent` in its `tools` array (or use `"tools": ["*"]` / `"@builtin"` to inherit all built-ins). Without it, the agent silently fails to delegate. Agents currently configured for delegation: `master`, `web-builder`, `ai-builder`.

## Kiro CLI Features Worth Knowing (through 2.13.0)

- **Agent output side channels** (2.3.0) — `$AGENT_DISPLAY_OUT` and `$AGENT_CONTEXT_OUT` env vars in shell commands route verbose output to the user TUI without polluting agent context (used by `deploy.sh`)
- **OAuth Client ID for HTTP MCP servers** (2.3.0) — set `oauth.clientId` in MCP config to use Slack/GitHub/Figma HTTP MCP servers without DCR (we don't need this — our MCPs are stdio)
- **`KIRO_HOME` env var** (2.3.0) — relocate the global config directory if needed
- **Configurable V2 TUI keybindings** (2.3.0) — remap Ctrl+C / Esc / quit if they conflict with tmux
- **`/rewind`** (2.4.0, enriched in 2.7.0) — jump back to an earlier prompt and branch into a new session; the turn picker now previews tool calls, files touched, and commands run per turn
- **Model reasoning effort** (2.4.0) — `/effort` (low / medium / high / xhigh / max) tunes how hard the model thinks; `--effort` sets it at launch (2.6.0)
- **Subagent review loops** (2.5.0) — reviewer→implementer loops for self-correcting pipelines (see "Subagent Review Loops" above)
- **Thinking display** (2.5.0) — streams the model's reasoning live; on by default, toggle via `/settings display`
- **Transcript export** (2.6.0) — `/transcript save` exports a conversation as markdown/plaintext/JSON
- **Persistent model + effort prefs** (2.6.0) — `/model` and `/effort` choices stick across sessions automatically (no more `set-current-as-default`)
- **`/goal`** (2.7.0) — start an iterative loop where the agent works toward an objective and must verify completion before stopping (default 5 iterations, `--max` configurable). Aligns with this config's quality-gate philosophy.
- **Queue steering** (2.7.0) — send a correction while the agent is working; it picks it up at the next tool boundary. `Ctrl+S` toggles steer mode (inject mid-turn) vs queue mode (buffer until turn ends).
- **MCP auth management** (2.11.0) — `/mcp auth`, `/mcp cancel-auth`, `/mcp logout` for remote MCP OAuth; MCP-panel shortcuts `^A`/`^X`/`^R`.
- **Expanded MCP OAuth** (2.12.0) — `clientSecret` + custom `redirectUri` callback paths + skip Dynamic Client Registration with your own `clientId` (e.g., Figma); more accurate approval prompts for combined-flag commands; full ASCII mode.
- **Config Hot-Reload** (2.10.0) — agent and MCP config changes reconcile **live on save**: no session restart, only affected MCP servers restart, conversation context preserved, order-independent diff (reordering env vars won't trigger a restart). Editing an agent JSON or `mcp.json` now takes effect immediately. Also adds `chat.disableInheritingDefaultResources` to stop custom agents from inheriting default steering/skills/AGENTS.md (they inherit by default since 2.7.0).

## Adaptive Thinking (Kiro CLI 2.2+)

Claude Opus 5 (experimental preview, 1M context window) is the default model. Reasoning automatically scales with task complexity and persists across multi-turn conversations. Keep `chat.enableThinking = true` (already set).
