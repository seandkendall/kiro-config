# Kiro CLI Setup

**Version:** 2026.04.30

Multi-agent AWS development environment for the Kiro CLI with specialized subagents, steering docs, and skills.

## What's New

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

### 2026.04.10a

- PostToolUse formatting hooks: ruff (Python), prettier (TS/HTML/CSS), shfmt (bash)
- `shell.autoAllowReadonly` + `aws.autoAllowReadonly` for smoother dev loops
- `web_fetch.trusted` patterns for AWS docs and GitHub
- Externalized long inline prompts to `file://` URIs
- Removed all legacy: gaming agents, nova-act, deprecated MCP servers, old schema fields

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed
- Python 3.13+ with `uv` and `uvx`
- Node.js 20+ with `npx`
- AWS CLI v2 configured with named profiles
- Git

## Installation

```bash
# Copy all files into your Kiro config directory
cp -r agents/ steering/ skills/ prompts/ settings/ ~/.kiro/

# Or to preserve existing files and only add new ones:
cp -rn agents/ steering/ skills/ prompts/ settings/ ~/.kiro/
```

## What's Included

### Agents (17)

| Agent         | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| `master`      | Orchestrator — routes to the right specialist subagent           |
| `serverless`  | AWS Lambda, API Gateway, DynamoDB, Step Functions, Powertools    |
| `frontend`    | React, TypeScript, Tailwind CSS, shadcn/ui, Playwright, Figma    |
| `testing`     | pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent   |
| `cypress`     | Cypress E2E tests, Page Objects, data-cy selectors               |
| `architect`   | Architecture diagrams, cost estimation, Well-Architected reviews |
| `ai-builder`  | Amazon Bedrock, Strands Agents, prompt engineering, RAG          |
| `agentcore`   | AWS AgentCore applications with Strands framework                |
| `devops`      | CloudWatch monitoring, alerting, cost optimization               |
| `data`        | DynamoDB single-table design, Postgres, data modeling            |
| `security`    | IAM, encryption, cdk-nag, CloudTrail                             |
| `docs`        | READMEs, API docs, ADRs, runbooks                                |
| `image-gen`   | Image generation via Bedrock (Nova Canvas + SD 3.5)              |
| `research`    | Deep research with web search, AWS docs, GitHub                  |
| `sap-abap`    | SAP ABAP — Clean ABAP, ALV, BAPIs, CDS, RAP                      |
| `accounting`  | Canadian accounting SaaS (Alberta-focused)                       |
| `web-builder` | React + AWS full-stack web applications                          |

### Steering Docs (15)

Rules and standards automatically loaded into every session: accessibility, API design, AWS/CDK patterns, development workflow, error handling, performance, Python standards, security policies, and more.

### Skills (7)

Specialized knowledge files loaded on-demand: AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, SAP ABAP, deploy-on-aws, and AWS architecture diagrams.

### MCP Servers

Agents configure their own MCP servers. Key servers used across agents:

| Server              | Agents                                                     | Purpose                              |
| ------------------- | ---------------------------------------------------------- | ------------------------------------ |
| Context7            | frontend, serverless, architect, data, web-builder, master | Live library docs (React, AWS, etc.) |
| Playwright          | frontend                                                   | Browser automation and E2E testing   |
| shadcn              | frontend, web-builder                                      | Component registry browsing/install  |
| 21st.dev Magic      | frontend, web-builder                                      | AI UI generation from descriptions   |
| Figma Framelink     | frontend                                                   | Design-to-code from Figma URLs       |
| Browser Lens        | frontend                                                   | Live CSS/layout debugging            |
| Sequential Thinking | master, frontend                                           | Structured reasoning chains          |
| DuckDuckGo          | master, research, sap-abap + 4                             | Privacy-first web search             |
| AWS Documentation   | master, serverless, architect, data                        | AWS docs search and retrieval        |
| AWS IaC             | serverless, architect, web-builder                         | IaC best practices                   |
| AWS Pricing         | architect                                                  | Real-time AWS pricing                |
| GitHub              | master                                                     | GitHub API (repos, PRs, issues)      |
| Chrome DevTools     | frontend, web-builder                                      | Chrome debugging                     |
| Bedrock Image       | frontend, web-builder, image-gen                           | Image generation                     |

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
