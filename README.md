# Kiro CLI Setup

**Version:** 2026.05.06

Multi-agent AWS development environment for the Kiro CLI with specialized subagents, steering docs, and skills.

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed
- Python 3.13+ with `uv` and `uvx`
- Node.js 20+ with `npx`
- AWS CLI v2 configured with named profiles
- Git

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

### Agents (18)

| Agent              | Description                                                      |
| ------------------ | ---------------------------------------------------------------- |
| `master`           | Orchestrator — routes to the right specialist subagent           |
| `serverless`       | AWS Lambda, API Gateway, DynamoDB, Step Functions, Powertools    |
| `frontend`         | React, TypeScript, Tailwind CSS, shadcn/ui, Playwright, Figma    |
| `testing`          | pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent   |
| `cypress`          | Cypress E2E tests, Page Objects, data-cy selectors               |
| `architect`        | Architecture diagrams, cost estimation, Well-Architected reviews |
| `ai-builder`       | Amazon Bedrock, Strands Agents, prompt engineering, RAG          |
| `agentcore`        | AWS AgentCore applications with Strands framework                |
| `devops`           | CloudWatch monitoring, alerting, cost optimization               |
| `data`             | DynamoDB single-table design, data modeling                      |
| `security`         | IAM, encryption, cdk-nag, CloudTrail                             |
| `docs`             | READMEs, API docs, ADRs, runbooks                                |
| `image-gen`        | Image generation via Bedrock (Nova Canvas + SD 3.5)              |
| `research`         | Deep research with web search, AWS docs, GitHub                  |
| `sap-abap`         | SAP ABAP — Clean ABAP, ALV, BAPIs, CDS, RAP                      |
| `accounting`       | Canadian accounting SaaS (Alberta-focused)                       |
| `web-builder`      | React + AWS full-stack web applications                          |
| `google-workspace` | Google Docs, Sheets, Drive (read-only)                           |

### Steering Docs (16)

Rules and standards automatically loaded into every session: accessibility, API design, AWS/CDK patterns, AWS Agent Toolkit usage, development workflow, error handling, performance, Python standards, security policies, and more.

### Skills (22)

| Source                 | Skills                                                                                                                                                                                                                                                          |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Custom (7)             | AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, SAP ABAP, deploy-on-aws, AWS architecture diagrams                                                                                                                               |
| AWS Agent Toolkit (15) | Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless decision guide, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing/cost, CloudFormation, messaging/streaming |

### MCP Servers

Agents configure their own MCP servers. Key servers used across agents:

| Server              | Agents                                                     | Purpose                              |
| ------------------- | ---------------------------------------------------------- | ------------------------------------ |
| AWS MCP Server      | All 18 agents                                              | Full AWS API, docs, skills, scripts  |
| Context7            | frontend, serverless, architect, data, web-builder, master | Live library docs (React, AWS, etc.) |
| Playwright          | frontend                                                   | Browser automation and E2E testing   |
| shadcn              | frontend, web-builder                                      | Component registry browsing/install  |
| 21st.dev Magic      | frontend, web-builder                                      | AI UI generation from descriptions   |
| Figma Framelink     | frontend                                                   | Design-to-code from Figma URLs       |
| Browser Lens        | frontend, web-builder                                      | Live CSS/layout debugging            |
| Sequential Thinking | master, frontend                                           | Structured reasoning chains          |
| DuckDuckGo          | master, research, sap-abap + 4                             | Privacy-first web search             |
| GitHub              | master, research, sap-abap, accounting, devops             | GitHub API (repos, PRs, issues)      |
| Chrome DevTools     | frontend, web-builder, testing                             | Chrome debugging                     |
| Bedrock Image       | frontend, web-builder, image-gen + 3                       | Image generation                     |
| Google Drive        | google-workspace                                           | Google Docs/Sheets/Drive (read-only) |

## Environment Variables

Set these before using agents that need them:

```bash
# Required for GitHub MCP server
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# Required for 21st.dev Magic UI generation
export TWENTY_FIRST_API_KEY="your_key_here"

# Required for Figma design-to-code
export FIGMA_API_KEY="your_key_here"
```

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

## License

Personal configuration — shared for reference and reuse.
