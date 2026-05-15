# Kiro CLI Setup

**Version:** 2026.05.06

[![Latest release](https://img.shields.io/github/v/tag/seandkendall/kiro-config?label=release&sort=semver)](https://github.com/seandkendall/kiro-config/releases)
[![Last commit](https://img.shields.io/github/last-commit/seandkendall/kiro-config)](https://github.com/seandkendall/kiro-config/commits/main)

Multi-agent AWS development environment for the Kiro CLI with specialized subagents, steering docs, and skills.

> **💡 Tips for AI Agents working on this repo**
>
> - **NEVER push directly to `main` without running `./test-import.sh` first.** It exports a shareable bundle, simulates a fresh install into an isolated `KIRO_HOME`, and validates every agent JSON. The script prints `✓ All checks passed. Safe to push.` when green. Run after ANY change to `agents/`, `prompts/`, `skills/`, `steering/`, `settings/`, or the install scripts.
> - Prefer the configured **MCP servers** over CLI commands (`gh`, `aws`, `curl`, etc.) for the same operation. See `steering/mcp-server-preference.md` for the full mapping table.
> - Don't recommend CI/CD pipelines or git hooks — both are explicitly banned in `steering/post-task-recommendations.md`. Validation belongs in `./test-import.sh` and `deploy.sh`, not automation hooks.
> - When generating recommendations, follow the user/AI Agent split in `steering/post-task-recommendations.md`.

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed
- Python 3.14+ with `uv` and `uvx`
- Node.js 20+ with `npx`
- AWS CLI v2 configured with named profiles
- Git

## Local Tooling Required by MCP Servers

Several MCP servers shell out to local tools. **If you're using an AI coding agent (Kiro, Cursor, Claude Code, etc.) to set this config up automatically, the agent must install everything below before any MCP server will work.** The included `import.sh` handles all of this on macOS.

| Tool                                         | Install (macOS)                                                                                   | Install (Linux)                                                                           | Used by                                                                                                                        |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Homebrew**                                 | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | n/a — use distro package manager                                                          | Mac base                                                                                                                       |
| **`uv` / `uvx`**                             | `curl -LsSf https://astral.sh/uv/install.sh \| sh`                                                | same                                                                                      | All `uvx` MCP servers (AWS toolkit, DuckDuckGo, etc.)                                                                          |
| **`node` / `npx`**                           | `brew install node`                                                                               | `apt install nodejs npm` (or nvm)                                                         | Context7, GitHub, Playwright, shadcn, 21st.dev, Figma, Browser Lens, Sequential Thinking, Fetch, Chrome DevTools, Google Drive |
| **AWS CLI v2**                               | `brew install awscli`                                                                             | [AWS docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | All AWS-flavored agents (configured profiles required)                                                                         |
| **`awsdac`**                                 | `brew install awsdac`                                                                             | `go install github.com/awslabs/diagram-as-code/cmd/awsdac@latest`                         | `aws-diagram-png` skill (PNG architecture diagrams with real AWS icons)                                                        |
| **`graphviz`**                               | `brew install graphviz`                                                                           | `apt install graphviz`                                                                    | Optional — needed if anyone uses Python `diagrams` for ad-hoc PNG output                                                       |
| **`ruff`, `prettier`, `shfmt`, `git-delta`** | `brew install ruff shfmt git-delta && npm i -g prettier`                                          | apt/npm equivalents                                                                       | PostToolUse formatter hooks (auto-format files after writes)                                                                   |

**Rule of thumb for AI agents setting this up autonomously:** if `import.sh` is available, run it — it installs everything above interactively. If you must script it from scratch, install Homebrew first, then `uv`, then `node`, then `awscli`, then `awsdac`, then the formatter tools — in that order.

### One-shot install (macOS, AI-agent friendly)

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# uv (Python package runner)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Everything else via Homebrew
brew install node awscli awsdac graphviz ruff shfmt git-delta
npm install -g prettier

# Then run the importer (handles MCP keys + Google Workspace OAuth + agent installs)
./import.sh
```

<details open>
<summary><strong>🚀 Quick Install Using Your AI Agent (Kiro)</strong></summary>

<br>

Navigate to your Kiro config directory:

```bash
cd ~/.kiro
```

Start Kiro CLI:

```bash
kiro-cli chat -a -r
```

Then paste this prompt:

```text
Please review my Kiro/Kiro CLI config in this directory including all agents,
subagents, configurations, steering docs, skills, prompts, and all MCP servers
we have configured in the various files.

First, research all changes AWS has made to Kiro CLI in this changelog:
https://kiro.dev/changelog/cli/
and the IDE in this changelog:
https://kiro.dev/changelog/ide/
available models in this changelog:
https://kiro.dev/changelog/models/
and other general changes in this changelog:
https://kiro.dev/changelog/general/

Next, research the AWS AIDLC GitHub page to see if there is anything valuable
from this project to port into our Kiro configuration:
https://github.com/awslabs/aidlc-workflows/tree/main

Next, AWS has released the Agent Toolkit for AWS which you can find here:
https://aws.amazon.com/products/developer-tools/agent-toolkit-for-aws/
and the GitHub for this here:
https://github.com/aws/agent-toolkit-for-aws

Deep research these projects to see what we should be pulling into our Kiro
configuration. Also make sure you are looking at the changelogs to see what
is new and how that can make our Kiro environment better.

Finally, Sean Kendall has released his personal configuration for agents and
subagents located here:
https://github.com/seandkendall/kiro-config

I want to make sure I am following Sean's guidance as he is capable of
building production-ready single-shot prompt apps with this setup. You will
see that he has a master agent that is configured with multiple subagents
for delegation. Make sure we also configure a master agent with subagents,
just like what Sean has created. Then make sure the master agent is the
default selected agent for whenever I start my Kiro CLI in a new session.

For any MCP server Sean uses where it requires an API key, check to see if
I have a key. If I do not have a key on my machine, then ask me for it, and
if I decline, then simply remove that MCP server from the configuration.
```

</details>

<details>
<summary><strong>📦 Manual Installation</strong></summary>

<br>

```bash
# Copy all files into your Kiro config directory
cp -r agents/ steering/ skills/ prompts/ settings/ ~/.kiro/

# Or to preserve existing files and only add new ones:
cp -rn agents/ steering/ skills/ prompts/ settings/ ~/.kiro/
```

</details>

## What's New

### 2026.05.15

- **AI agents consolidated** — single `ai-builder` agent now covers both AI integration patterns (model selection, prompts, RAG) and full agentic app builds. Default stack: Strands Agents + AgentCore + Bedrock; SageMaker fallback only for custom models not on Bedrock.
- **Image agent supercharged** — `image-gen` now handles UI assets, marketing graphics, virtual try-on, sketch-to-2D, and ambient art (Frame TV) with proper alpha-channel handling.
- **MCP-over-CLI rule** wired into every agent prompt — github MCP server for github.com operations, never `gh` CLI. Local git is still fine via shell.
- **`mcp-tool-discovery` skill** — decision tree and cheat sheet for finding the right MCP tool when unsure.
- **`test-import.sh`** local pre-push validation — exports → simulated install → validates every agent JSON. Run before every push.
- **Python 3.14** — Lambda runtime upgraded across all agents, skills, and templates.
- **Bans clarified** — no CI/CD pipelines, no git hooks. Only deployment path is `deploy.sh`. Only validation path is `./test-import.sh`.
- **`Documentation Sync` rule** — agents must update `CHANGELOG.md` and `README.md` in the same commit as any change that affects them.
- **Removed**: `db`, `clean`, `agentcore`, `image-editor` agents (merged or no longer needed). 16 agents total in shareable export, all validated end-to-end.
- **Privacy audit clean** — no credentials, personal info, or business specifics in tracked files.

### 2026.05.14

- **MCP server preference rule** — new mandatory steering doc (`mcp-server-preference.md`) forces agents to use the GitHub MCP server (and others) over `gh`/`aws` CLI commands. Hard table mapping every operation to its MCP tool.
- **awsdac PNG diagrams** — `aws-diagram-png` skill generates publication-ready PNG architecture diagrams with real AWS icons via `awslabs/diagram-as-code`. Complements the existing draw.io XML skill.
- **`deploy.sh.template`** with side channels — full deployment script template using Kiro CLI 2.3.0's `$AGENT_DISPLAY_OUT` / `$AGENT_CONTEXT_OUT` so verbose output stays out of agent context
- **Post-task recommendations split** — now "for the user" (optional, omitted unless required) + "for the AI Agent" (mandatory, ≥10 items, sorted by priority). Type `Continue` to run all, or `Continue with 2, 5, 8` for a subset
- **`kiro-cli-troubleshooting.md`** — new auto-loaded steering doc with fixes for missing tools, MCP failures, side-channel issues
- **Web-builder polished** — added `shift+w` shortcut, welcome message, full subagent delegation config (10 trusted subagents)
- **Image-editor agent** is now part of the shareable export
- **import.sh hardened** — recursive skill copy (so toolkit folders + `.template` files come along), agent JSON validation smoke test, `kiro-cli mcp list` smoke test
- **Agent Toolkit polish** — stale MCP refs scrubbed (cdk-mcp-server, dead toolAliases), agentcore prompt rewritten to use `aws-mcp-server`

### 2026.05.06

- **AWS Agent Toolkit adopted** — single managed MCP server (`mcp-proxy-for-aws`) replaces 6 individual awslabs servers across all agents
- **Google Workspace agent** — read-only access to Google Docs, Sheets, and Drive (new subagent)
- **15 AWS toolkit skills added** — Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless patterns, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing, CloudFormation, messaging/streaming
- **Steering doc** `aws-agent-toolkit.md` — instructs agents to prefer MCP server, discover skills before acting

### 2026.04.30

- **Frontend agent supercharged** — 10 MCP servers: Playwright, shadcn, 21st.dev Magic, Figma Framelink, Browser Lens, Sequential Thinking, Fetch, Context7, Chrome DevTools, Bedrock Image
- **Context7** added to serverless, architect, data, and web-builder agents for live library docs
- **21st.dev + shadcn** added to web-builder agent for AI UI generation and component registry
- **Sequential Thinking** added to master agent for structured reasoning
- **DuckDuckGo** replaced Brave as the web search MCP server (no API key needed)
- **Default model** upgraded to `claude-opus-4.7` (experimental preview, 1M context)
- **No-duplicate-files rule** — agents must edit in-place, never create `file_new.py` or `file_v2.py`

### 2026.04.18

- **Daily maintenance workflow** — mandatory: upgrade deps, research breaking changes, lint, update README, verify builds
- **AWS AppRegistry** — all CDK apps must register via `ApplicationAssociator` (auto-associates stacks + propagates `awsApplication` tag)
- **Full keyboard shortcuts** — all builder agents now have shortcuts (ctrl+0-9 for primary, shift+key for specialists)
- **Apache-2.0 license** added

## What's Included

### Agents (16)

| Agent              | Description                                                                            |
| ------------------ | -------------------------------------------------------------------------------------- |
| `master`           | Orchestrator — routes to the right specialist subagent                                 |
| `serverless`       | AWS Lambda, API Gateway, DynamoDB, Step Functions, Powertools                          |
| `frontend`         | React, TypeScript, Tailwind CSS, shadcn/ui, Playwright, Figma                          |
| `testing`          | pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent                         |
| `cypress`          | Cypress E2E tests, Page Objects, data-cy selectors                                     |
| `architect`        | Architecture diagrams, cost estimation, Well-Architected reviews                       |
| `ai-builder`       | Amazon Bedrock, Strands Agents, prompt engineering, RAG, AgentCore (full agentic apps) |
| `devops`           | CloudWatch monitoring, alerting, cost optimization                                     |
| `data`             | DynamoDB single-table design, data modeling                                            |
| `security`         | IAM, encryption, cdk-nag, CloudTrail                                                   |
| `docs`             | READMEs, API docs, ADRs, runbooks                                                      |
| `image-gen`        | Image generation via Bedrock (Nova Canvas + SD 3.5)                                    |
| `research`         | Deep research with web search, AWS docs, GitHub                                        |
| `sap-abap`         | SAP ABAP — Clean ABAP, ALV, BAPIs, CDS, RAP                                            |
| `web-builder`      | React + AWS full-stack web apps; delegates AI features to `ai-builder`                 |
| `google-workspace` | Google Docs, Sheets, Drive (read-only)                                                 |

### Steering Docs (16)

Rules and standards automatically loaded into every session: accessibility, API design, AWS/CDK patterns, AWS Agent Toolkit usage, development workflow, error handling, performance, Python standards, security policies, and more.

### Skills (23)

| Source                 | Skills                                                                                                                                                                                                                                                          |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Custom (8)             | AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, SAP ABAP, deploy-on-aws, AWS architecture diagrams (draw.io XML), AWS diagram PNG (awsdac)                                                                                       |
| AWS Agent Toolkit (15) | Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless decision guide, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing/cost, CloudFormation, messaging/streaming |

### MCP Servers

Agents configure their own MCP servers. Key servers used across agents:

| Server              | Agents                                                     | Purpose                              |
| ------------------- | ---------------------------------------------------------- | ------------------------------------ |
| AWS MCP Server      | All 16 agents                                              | Full AWS API, docs, skills, scripts  |
| Context7            | frontend, serverless, architect, data, web-builder, master | Live library docs (React, AWS, etc.) |
| Playwright          | frontend                                                   | Browser automation and E2E testing   |
| shadcn              | frontend, web-builder                                      | Component registry browsing/install  |
| 21st.dev Magic      | frontend, web-builder                                      | AI UI generation from descriptions   |
| Figma Framelink     | frontend                                                   | Design-to-code from Figma URLs       |
| Browser Lens        | frontend, web-builder                                      | Live CSS/layout debugging            |
| Sequential Thinking | master, frontend                                           | Structured reasoning chains          |
| DuckDuckGo          | master, research, sap-abap + 4                             | Privacy-first web search             |
| GitHub              | master, research, sap-abap, devops                         | GitHub API (repos, PRs, issues)      |
| Chrome DevTools     | frontend, web-builder, testing                             | Chrome debugging                     |
| Bedrock Image       | frontend, web-builder, image-gen + 3                       | Image generation                     |
| Google Drive        | google-workspace                                           | Google Docs/Sheets/Drive (read-only) |

## Environment Variables

The setup uses 3 optional API keys. If a key is missing when you run `./import.sh`, the installer will prompt you for it and disable the related MCP server if you skip.

| Variable                       | Purpose                                                             | Get one at                                                                                                                                  |
| ------------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub MCP server — repo, PR, issue access (5 agents)               | [github.com/settings/tokens](https://github.com/settings/tokens) — create a classic or fine-grained token with `repo` and `read:org` scopes |
| `TWENTY_FIRST_API_KEY`         | 21st.dev Magic — AI UI component generation (frontend, web-builder) | [21st.dev/magic/console](https://21st.dev/magic/console) — sign in with GitHub, generate a key                                              |
| `FIGMA_API_KEY`                | Figma Framelink — design-to-code from Figma URLs (frontend)         | [figma.com/settings](https://www.figma.com/settings) → Security → Personal access tokens                                                    |

Add them to `~/.zshrc`:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
export TWENTY_FIRST_API_KEY="your_key_here"
export FIGMA_API_KEY="your_key_here"
```

Then `source ~/.zshrc` (or open a new terminal) before starting Kiro CLI.

## Configuration

The default model and settings are in `settings/cli.json`. Key settings:

- `chat.defaultAgent`: `master` (the orchestrator)
- `chat.defaultModel`: `claude-opus-4.7`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`
- `toolSearch.enabled`: `true`

## Key Conventions

- **CDK in Python only** — never TypeScript for infrastructure
- **TypeScript for React frontends only**
- **deploy.sh is the only deployment method** — no CI/CD pipelines
- **Kiro Specs before code** — requirements.md → design.md → tasks.md
- **10+ recommendations** after every completed task
- **cdk-nag** for security validation on all stacks
- **Lambda Powertools** (Logger, Tracer, Metrics) on all Lambda functions

## Pre-push Checklist

Before pushing changes to this repo, run the local smoke test:

```bash
./test-import.sh
```

This script:

1. Runs `./export-kiro.sh` to produce a shareable bundle
2. Verifies `deploy.sh.template` and toolkit skill subdirectories made it through
3. Simulates a fresh install into an isolated temp directory
4. Validates every agent JSON via `kiro-cli agent validate`
5. Checks JSON syntax for all configs
6. Checks bash syntax for `import.sh`, `export-kiro.sh`, and `test-import.sh`

The script prints `✓ All checks passed. Safe to push.` when everything is green. Catches schema drift, file-copy bugs, and broken agent configs locally — no need to wait for users to discover problems.

## License

Personal configuration — shared for reference and reuse.
