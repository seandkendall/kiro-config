# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.0] - First public release

A multi-agent AWS development environment for the Kiro CLI. Includes a master orchestrator that delegates to 12 specialist subagents, 16 always-available steering docs, 24 skills covering AWS patterns and custom workflows, and a curated MCP server stack centered on the AWS Agent Toolkit.

### Agents (15)

- **Orchestrators** — `master` (default, ctrl+1), `web-builder`, `ai-builder`
- **Specialists** — `serverless`, `frontend`, `testing`, `cypress`, `architect`, `data`, `devops`, `security`, `docs`, `image-gen`, `research`, `google-workspace`

The master agent runs up to 4 subagents in parallel and returns consolidated results. `web-builder` and `ai-builder` are themselves orchestrators that delegate frontend/backend/AI work to the relevant specialists.

### Steering Docs (16, always-loaded)

Accessibility, AGENTS, API standards, AWS Agent Toolkit, AWS standards, development workflow, error handling, Kiro CLI troubleshooting, MCP server preference, performance optimization, post-task recommendations, product, Python standards, security policies, session continuity, structure, tech, troubleshooting — plus the meta-rule `personal-rules-protocol` that drives self-evolving local rules.

### Skills (24)

- **Custom (8)** — AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, deploy-on-aws, AWS architecture diagrams (draw.io XML), AWS diagram PNG (awsdac), personal rules management
- **AWS Agent Toolkit (16)** — Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless decision guide, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing/cost, CloudFormation, messaging/streaming, MCP tool discovery

### MCP Servers

- `aws-mcp-server` (Agent Toolkit for AWS) — single managed entry point for all AWS interactions on every agent
- `github` — GitHub API operations (mandated over `gh` CLI)
- `context7` — live library docs
- `playwright`, `chrome-devtools`, `browser-lens` — browser automation and CSS debugging
- `shadcn`, `21st-dev-magic`, `figma-framelink` — UI generation and design-to-code
- `sequentialthinking` — structured reasoning chains
- `bedrock-image-mcp-server` — image generation via Nova Canvas + SD 3.5
- `duckduckgo` — privacy-first web search
- `google-drive` — read-only Google Workspace access

### Self-Evolving Personal Rules

When the user states a preference using "always / never / from now on / I prefer …" OR repeats a preference 2+ times in a session, the agent proposes saving it as a `personal-<topic>.md` steering doc. Personal rules:

- Are gitignored (`steering/personal-*.md`, `agents/personal-*.json`, `prompts/personal-*.md`)
- ALWAYS win over base rules on the user's machine
- Have built-in PII/credentials guard (refuses to save AWS keys, API tokens, emails, phone numbers, JDBC URLs, private keys)
- Surface stale entries (>60 days) for review

### Tooling Standards

- **CDK in Python only** — never TypeScript for infrastructure
- **TypeScript only for React frontends**
- **Python 3.14** Lambda runtime across all agents and templates
- **`deploy.sh` is the only deployment method** — no CI/CD pipelines, no git hooks (both explicitly banned)
- **MCP-over-CLI rule** — github MCP for github.com operations (never `gh`); `aws-mcp-server` for AWS (never bare `aws` CLI)
- **`./validate.sh`** — local pre-push validation. Validates all 15+ agent JSONs, JSON syntax, bash syntax, and gitignore privacy guard.
- **Documentation Sync rule** — `CHANGELOG.md` and `README.md` updates ship in the same commit as the change that affects them

### Default Configuration

- `chat.defaultAgent`: `master`
- `chat.defaultModel`: `claude-opus-4.7`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`
- `toolSearch.enabled`: `true`
