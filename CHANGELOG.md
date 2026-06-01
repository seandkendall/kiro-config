# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.2] - master-demo-single agent

### Added

- **`master-demo-single` agent** — single-agent variant of `master-demo` for demos that benefit from one continuous thread of work rather than parallel orchestration. Same hard scope as `master-demo` (no UI, WAF, Route53/custom domains, AppRegistry, Powertools, X-Ray, cdk-nag, Kiro Specs, CI/CD) but with key simplifications:
  - **No subagents.** This agent does everything itself — write CDK, write Lambda handlers, deploy via `./deploy.sh -y`, verify endpoints + CORS. The whole demo is one linear flow.
  - **Only `aws-mcp-server`** (the AWS Agent Toolkit's core MCP). No `github`, no `web-search`, no `context7`, no `sequentialthinking`. Lean on purpose.
  - **`aws-serverless` skill bundle as primary reference** — covers Lambda configuration, API Gateway debugging, Step Functions, EventBridge, event source mappings, cold starts, deployment with SAM/CDK, troubleshooting.
  - Uses the v0.11.0 `deploy.sh` contract with `-y` for auto-confirm.
  - Keyboard shortcut: `ctrl+7`.
- README agent table updated: 16 → 17 agents
- AWS MCP Server count: "All 16 agents" → "All 17 agents"
- AGENTS.md "When to Use Which Agent" updated with `master-demo-single` and routing guidance ("use when the demo benefits from one continuous thread of work rather than parallel orchestration")

### When to use which demo agent

| Agent                         | Best for                                                                                                 |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| `master-demo` (shift+m)       | Demos showing how subagents fan out in parallel — the orchestration IS the show                          |
| `master-demo-single` (ctrl+7) | Demos where the audience benefits from one focused, linear thread — no orchestration overhead to explain |

Both follow identical hard rules; the only difference is whether subagents are involved.

## [0.11.1] - Time-budget removal + deploy.sh template hardening

### Removed

- **All time budgets from `master-demo`** — the previous "10-MINUTE BUDGET" framing in `prompts/master-demo.md` directly violated the existing **"No Time Estimates (MANDATORY)"** rule in `steering/development-workflow.md`. Renamed `SPEED RULES` → `EFFICIENCY RULES`. Dropped every "10 minutes / 10-minute / under N minutes" reference. The same 9 efficiency tradeoffs (skip Specs, HTTP API, PAY_PER_REQUEST, single stack, no Layers, etc.) are kept — they're concrete tradeoffs, not time estimates.
- Added an explicit `NO TIME ESTIMATES` reminder block in `master-demo.md` cross-referencing `development-workflow.md`. If asked "how long?", respond with scope (number of stacks, services, resources) — never time.
- `master-demo.json` `welcomeMessage` updated: dropped "<10min budget", trimmed to 175 chars.

### Added

- **`skills/gitignore.template`** (96 lines) — copy-paste-ready `.gitignore` for AWS CDK + React projects deployed via `deploy.sh`. Includes `.deploy-state.json` (per-profile state file from the v0.11.0 contract), all `.env*` patterns, AWS credential files, CDK output dirs, Python/Node/Vite caches, Cypress artifacts, editor/OS junk.
- **`ai-builder.md`** — explicit deploy.sh contract reference added to the AgentCore app-build orchestration section. Lists the 5 flags, points to `.deploy-state.json` for per-profile state, references `skills/deploy.sh.template`. (master.md and web-builder.md don't deploy directly — they delegate to `serverless` which inherits the contract from `aws-standards.md`.)

### Changed

- **`master-demo` prompt — explicit `-y` flag usage in deployment flow.** All `./deploy.sh` invocations now show `./deploy.sh -y` (deploy) and `./deploy.sh --delete -y` (teardown), making the demo's auto-confirm pattern explicit.
- **`skills/deploy.sh.template` Route53 cleanup made concrete.** The previous `# TODO: Route53 record cleanup` placeholder is replaced with a working implementation:
  - Walks up the domain levels to find the hosted zone (e.g., `d1.app.example.com` → `app.example.com` → `example.com`)
  - Lists any `RecordSets` whose Name matches the deployed domain (these are orphans `cdk destroy` left behind)
  - Asks the user to confirm before deletion (skipped under `-y`)
  - Builds a Route53 change-batch with `DELETE` actions and submits via `change-resource-record-sets`
  - **Never deletes the hosted zone itself** — zones are treated as shared infra across projects in the account

## [0.11.0] - deploy.sh full contract + Claude Opus 4.8

### Changed

- **Default model bumped: `claude-opus-4.7` → `claude-opus-4.8`**
  - `settings/cli.json` `chat.defaultModel` updated
  - `steering/AGENTS.md` "Adaptive Thinking" section updated
  - `steering/tech.md` "Kiro CLI Tooling" section updated
  - README "Configuration" section updated
  - The historical `4.6 → 4.7` migration note in `skills/amazon-bedrock/references/model-migration.md` is kept intentionally — it documents prior migration history, not the current default

### Added

- **Full `deploy.sh` contract** specified in `steering/aws-standards.md`. Every project's `deploy.sh` MUST follow it:
  - **Flags**: `--profile <name>` (defaults to `default`), `--domain <fqdn>`, `--delete`, `-y`/`--yes`, `-h`/`--help`
  - **Per-profile state** in `.deploy-state.json` (gitignored). When `--domain` is passed, the value is saved keyed by AWS profile. Subsequent runs without `--domain` recall the saved value for the current profile.
  - **Deep-cleanup on `--delete`**: empties + deletes S3 buckets, deletes CloudWatch log groups, removes Route53 records the stack added (without deleting the zone), deletes ACM certificates the stack created, deletes SQS/SNS/EventBridge/ECR resources owned by the stack, detaches and deletes IAM roles + policies. Discovery is by tag (`project=<name>`), never by name prefix.
  - **`-y` auto-confirm flag**: skips every interactive prompt (intended for CI-like usage and `master-demo`)
  - **Multi-project safety in shared AWS accounts**: discovery by tag (NOT by name prefix), surgical Route53 record deletion (never delete the hosted zone if shared), pre-flight resource list shown before deletion, `CDKToolkit` bootstrap stack is NEVER destroyed by `deploy.sh --delete`
- **Reference template**: `skills/deploy.sh.template` fully rewritten (330 lines) implementing the contract end-to-end
- **`skills/deploy-on-aws.md`** updated to summarize the contract and link back to the canonical rule in `steering/aws-standards.md`

### Why

The previous `deploy.sh` contract was minimal (`--profile`, `--delete`). Three real-world pain points led to this expansion:

1. **Manual domain re-typing**: every redeploy required passing `--domain` again. Now saved per-profile in `.deploy-state.json`.
2. **Orphaned resources after `cdk destroy`**: non-empty S3 buckets, retained CloudWatch log groups, lingering ACM certs. Now `--delete` deep-cleans by tag.
3. **Cross-project blast radius in shared AWS accounts**: deleting a stack could nuke Route53 records or ACM certs owned by sibling projects. Now discovery is tag-based and the `CDKToolkit` is explicitly excluded from `--delete`.

## [0.10.3] - master-demo speed optimization

### Changed

- **`master-demo` rebuilt for speed** — total time from "user describes the build" to "all endpoints tested and CORS verified" must fit under **10 minutes**. New `SPEED RULES (10-MINUTE BUDGET)` section in the prompt with 9 concrete speedups in priority order:
  - Skip Kiro Specs phase (replace with 3-bullet inline plan; biggest win)
  - HTTP API instead of REST API (faster deploy, native CORS, lower cold start)
  - DynamoDB PAY_PER_REQUEST (no provisioned capacity)
  - Single stack, no nested stacks
  - Inline Lambda code or single-file `PythonFunction`, no Lambda Layers
  - `cdk deploy --require-approval never`, skip `cdk diff`
  - Unit tests off the critical path (post-deploy endpoint sweep IS the test suite)
  - Plain `logging.getLogger`, not Lambda Powertools
  - Skip cdk-nag during demo, run after if asked
- Expanded NEVER list with 8 new explicit overrides of base steering rules: AppRegistry, Powertools, X-Ray, DLQ + idempotency, Layers, resource tagging, Cognito/auth, request models, cdk-nag, Kiro Specs. Each entry calls out the base rule it's overriding and why master-demo's "demo only" scope authorizes the override.
- `welcomeMessage` updated to 185 chars and signals speed mode: "master-demo ready. AWS serverless, <10min budget. No UI/WAF/AppRegistry/Powertools/X-Ray/cdk-nag/Kiro-Specs..."

### Why

Live demos compete for attention. A 30-minute build loses the room. The 10-minute budget forces decisions about which production-grade rules add demo-time noise (cdk-nag, AppRegistry, Powertools observability stack, full Kiro Spec phase) and which stay (CORS verification, endpoint testing, default account, no WAF/Route53/custom domains). The base steering docs still apply to production projects — master-demo's overrides are scoped to the agent itself.

## [0.10.2] - AWS Support Case Ban

### Added

- **`AWS Support Case Ban (STRICT)`** — new section in `steering/post-task-recommendations.md` alongside the existing CI/CD and Git Hook bans. Hard rule: agents NEVER auto-open AWS Support cases (technical, account/billing, service-limit-increase) or call Service Quotas API for quota requests without explicit user instruction. When a quota wall is hit, surface the limit and recommend the user open the case manually.
- Mirror cross-reference added to `steering/aws-agent-toolkit.md` ("AWS Support API Guard" section) since `aws-mcp-server` exposes the AWS Support API. The MCP-over-CLI rule does NOT authorize unattended case creation.

## [0.10.1] - master-demo agent

### Added

- **`master-demo` orchestrator agent** for live serverless backend demos. Showcases parallel subagent execution as a teaching tool. Hard scope:
  - ALWAYS: AWS serverless, default AWS account, post-deploy endpoint sweep, CORS verification (preflight + actual), parallel subagents, OpenAPI 3 native, can inspect public frontend pages to design matching backends
  - NEVER: UI code, browser testing (Cypress/Playwright), WAF, Route53/custom domains/ACM certs, ServiceCatalog AppRegistry (explicit override of the base aws-standards rule — demos skip it), CI/CD pipelines
- 9 subagents available: `serverless` (primary), `architect`, `data`, `security`, `testing`, `devops`, `docs`, `research`, `ai-builder`
- Keyboard shortcut: `shift+m`
- 5 MCP servers (mirror of master): `aws-mcp-server`, `github`, `web-search`, `context7`, `sequentialthinking`
- README agent table updated: 15 → 16 agents
- AWS MCP Server count: "All 15 agents" → "All 16 agents"
- AGENTS.md "When to Use Which Agent" updated with `master-demo`

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
- `chat.defaultModel`: `claude-opus-4.8`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`
- `toolSearch.enabled`: `true`
