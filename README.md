# Kiro CLI Setup

**Version:** 2026.04.10a

Multi-agent AWS development environment for the Kiro CLI with specialized subagents, steering docs, and skills.

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
| `frontend`    | React, TypeScript, Tailwind CSS, shadcn/ui                       |
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

### MCP Servers (Global)

These are configured in `settings/mcp.json` and available to all agents:

| Server                   | Type  | Purpose                   |
| ------------------------ | ----- | ------------------------- |
| `fetch`                  | stdio | Fetch web content         |
| `awsknowledge`           | HTTP  | AWS architecture guidance |
| `aws-iac-mcp-server`     | stdio | IaC best practices        |
| `aws-pricing-mcp-server` | stdio | Real-time AWS pricing     |

Individual agents also configure their own MCP servers (AWS docs, CloudWatch, GitHub, Context7, etc.).

## Environment Variables

Set these before using agents that need them:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
```

## Configuration

The default model and settings are in `settings/cli.json`. Key settings:

- `chat.defaultAgent`: `master` (the orchestrator)
- `chat.defaultModel`: `claude-opus-4.6`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`

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
