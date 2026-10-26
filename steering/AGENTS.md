---
inclusion: always
name: AGENTS
description: 'Multi-agent orchestration architecture, master/subagent ecosystem, delegation rules, subagent vs delegate semantics, subagent review loops, Kiro CLI 2.34.0+ features. Use when building or routing across agents.'
---

# AGENTS.md

## Agent Ecosystem Overview

This workspace uses a multi-agent architecture with a master orchestrator and specialized subagents.

## When to Use Which Agent

- **`/agent master`** (ctrl+1) — Default. Routes to the right specialist.
- **`/agent signals`** (shift+a) — Standalone AWS observability: CloudWatch Application Signals (service health, SLOs, distributed tracing, root cause analysis). No subagents.
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
| `image-gen`        | Image generation via Bedrock Image — Stable Diffusion 3.5 / Stability AI (Nova Canvas retired)                   |
| `research`         | Web search, AWS docs, GitHub, library docs                                                                       |
| `web-builder`      | React + AWS full-stack web apps; itself orchestrates frontend/serverless/ai-builder when scaffolding entire apps |
| `google-workspace` | Google Docs, Sheets, Drive (read-only)                                                                           |
| `email-research`   | IMAP/SMTP mailbox search, read, organize via MCP (optional, local credentials only)                              |

## Delegation Rules

- This config has run up to 4 subagents in parallel without issue; there's no documented hard ceiling — scale up if a task genuinely benefits, scale back only on actual resource/rate issues.
- Subagents cannot communicate with each other — only report back to the parent
- Use @path syntax to reference files inline — saves tool calls and tokens
- **Orchestrators can call other orchestrators** (max 2 hops to avoid context fragmentation). `master` → `web-builder` (full-stack scaffolds) / `ai-builder` (agentic apps). `web-builder` → `ai-builder` when an app needs AI features. `ai-builder` → `web-builder`'s subagents (frontend, serverless) for the app shell.
- **Subagent review loops (2.5.0+).** A reviewer stage can bounce work back to the implementer and loop until the bar is met, before results return to the parent — e.g., `serverless` implements → `security` reviews → loops back if cdk-nag findings remain. Set a `loop_to` target with a `trigger` phrase and a `max_iterations` cap.
- **Hooks consolidated into one global hook (migrated).** The 17 agents that previously carried an identical inline `hooks` block (`postToolUse` → `fs_write` → `hooks-bin/format-written-file.sh`) now rely on a single global hook at `~/.kiro/hooks/format-on-save.json` instead. Global hooks are V3-only; `settings/cli.json` already sets `chat.agentEngine: v3`, so this repo has been on the V3 baseline since before this migration — the old "V3 has no GA date" framing was stale. One caveat: `kiro-cli --cloud` sessions sync `hooks/` via Configuration Sync but do NOT sync `hooks-bin/` (only 7 top-level folders sync: `steering/`, `agents/`, `hooks/`, `skills/`, `powers/`, `settings/`, `workflows/`). In a cloud session the hook command will therefore not find the script and no-op — by design, the script fails closed (does nothing) rather than erroring, so this is safe, just not functional for actual formatting in cloud. Inline the script into the hook's `command` if cloud-side formatting is ever required.

## Subagent Review Loops

A quality-gate pipeline wires a reviewer stage that can bounce work back:

- The reviewer emits a trigger phrase (e.g., `NEEDS_CHANGES`) when work isn't acceptable
- That trigger loops the task back to the implementer with the reviewer's feedback as context
- A `max_iterations` cap stops the loop even if the bar is never met

Good fits: **Code review** (implementer → `security`/`testing` reviews → loops on failures), **Refactor** (implementer → reviewer checks behavior preserved → loops until clean), **Docs accuracy** (`docs` drafts → `research` verifies claims → loops on unverified statements). Keep `max_iterations` low (2–3) for demos, tight for production.

## `subagent` vs `delegate` — Which Tool to Use

| Capability | Semantics | When to use |
| --- | --- | --- |
| **subagent invocation** | Synchronous, parallel, isolated context. ~4 at once typical, not a hard cap. Returns results to parent. | DEFAULT — use whenever the parent needs the result to continue. |
| **`delegate`** | Asynchronous background task. Check status with `/delegate status`. | NICHE — only when the user keeps working in the foreground and doesn't need the result in-band. |

If unsure, use subagent invocation.

**The literal, callable name of the subagent-invocation tool is NOT stable across sessions or Kiro CLI versions — do not hardcode one.** Confirmed variants seen in practice: `subagent`, `use_subagent`, `orchestrate_subagent`, `invoke_sub_agent`, and `subagent_<agentname>` (one discrete tool per target agent). A prompt that hardcodes any single one of these will eventually hit `Tool "X" is not available` when a session exposes it under a different name — the same failure class as `steering/aws-agent-toolkit.md` → "Resolving the correct tool name" for the AWS MCP Server.

**Describe subagent delegation by capability/intent** ("delegate to the 'frontend' subagent"), not by a specific tool-name string. If a prompt needs to reference the mechanism explicitly: "the subagent-invocation tool (name varies by session — check the available tools list)".

**If a subagent call fails with `Tool "X" is not available`**: do not retry the same literal string. Check the session's available/loaded tools for whichever subagent-invocation tool is present. If none exists, the agent's `tools` array is likely missing the capability.

> **Custom orchestrator agents must declare the subagent-invocation capability.** Include `subagent` in the `tools` array (or `"tools": ["*"]` / `"@builtin"`). Without it, the agent silently fails to delegate. Agents currently configured for delegation: `master`, `web-builder`, `ai-builder`.

## Kiro CLI Features

For a running log of Kiro CLI feature releases (agent output side channels, OAuth, `/rewind`, model effort, subagent review loops, cloud sessions, `/voice`, global hooks, etc.), see `steering/kiro-cli-features-log.md` (manual inclusion — load it when you need to check what shipped in a specific version, not on every session).

## Capability Placement

Deciding whether a new capability belongs in a steering doc, a skill, a script/MCP tool, or a
sub-agent is its own decision framework — see `steering/capability-placement.md` (manual
inclusion — load it when adding a new rule, skill, or MCP integration).

## Adaptive Thinking (Kiro CLI 2.2+)

Adaptive thinking scales reasoning automatically with task complexity and persists across multi-turn conversations. Keep `chat.enableThinking = true` (already set). The default model itself is a setting, not steering guidance — see `settings/cli.json` → `chat.defaultModel` (or run `kiro-cli chat --list-models` to see the current default and all available models). Don't duplicate the model name here; it drifts out of sync with the actual setting.
