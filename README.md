# Kiro CLI Setup

**Version:** 0.27

[![Latest release](https://img.shields.io/github/v/tag/seandkendall/kiro-config?label=release&sort=semver)](https://github.com/seandkendall/kiro-config/releases)
[![Last commit](https://img.shields.io/github/last-commit/seandkendall/kiro-config)](https://github.com/seandkendall/kiro-config/commits/main)
[![License](https://img.shields.io/github/license/seandkendall/kiro-config)](LICENSE)

Multi-agent AWS development environment for the Kiro CLI — master orchestrator, 20 specialist subagents (incl. native iOS + iOS-testing + Amazon Ring), 26 steering docs, 16 skills, and a curated MCP server stack centered on the AWS Agent Toolkit.

> **💡 Tips for AI Agents working on this repo**
>
> - **NEVER push directly to `main` without running `./validate.sh` first.** It validates every agent JSON, JSON syntax, bash syntax, and the gitignore privacy guard. The script prints `✓ All checks passed. Safe to push.` when green. Run after ANY change to `agents/`, `prompts/`, `skills/`, `steering/`, `settings/`, or `import.sh`.
> - Prefer the configured **MCP servers** over CLI commands (`gh`, `aws`, `curl`, etc.) for the same operation. See `steering/mcp-server-preference.md` for the full mapping table.
> - Don't recommend CI/CD pipelines or git hooks — both are explicitly banned in `steering/post-task-recommendations.md`. Validation belongs in `./validate.sh` and `deploy.sh`, not automation hooks.
> - When generating recommendations, follow the user/AI Agent split in `steering/post-task-recommendations.md`.

See [Releases](https://github.com/seandkendall/kiro-config/releases) for the latest version notes.

## Installation

The **AI-assisted install is the primary path** — your Kiro agent fetches the repo, merges with any existing config, installs tooling, and validates the config. The manual clone and the macOS one-shot script (below, under Local Tooling) are fallbacks.

<details open>
<summary><strong>🚀 Quick Install Using Your AI Agent (Kiro)</strong></summary>

<br>

No manual cloning needed — the agent fetches the repo and does all the work, including merging with any Kiro config you already have.

Go to your Kiro config directory (created if it doesn't exist yet):

```bash
mkdir -p ~/.kiro && cd ~/.kiro
```

Start Kiro CLI:

```bash
kiro-cli chat -a -r
```

Then paste this prompt:

```text
Set up (or upgrade) my Kiro/Kiro CLI configuration in ~/.kiro using this
config repo: https://github.com/seandkendall/kiro-config
Do ALL the work yourself — I have NOT cloned anything.

CONTEXT: You are running inside ~/.kiro (verify with pwd before writing
anything). I may already have an existing Kiro config here — it MUST be
preserved and merged with the repo's config, never wiped.

STEP 1 — Acquire the repo WITHOUT touching my config yet: clone it to a
temp directory (git clone https://github.com/seandkendall/kiro-config.git
/tmp/kiro-config). If git or network access fails, fetch the files via
the GitHub API / raw.githubusercontent.com instead.

STEP 2 — Merge into ~/.kiro (NON-DESTRUCTIVE — ask when unsure):
- Fresh setup (no agents/steering/skills here yet): copy everything over
  (agents/, steering/, skills/, prompts/, settings/, import.sh, README.md,
  CHANGELOG.md, .gitignore, validate.sh), then initialize git (git init,
  remote add origin, fetch, reset --soft to origin/main) so I can pull
  future updates.
- Existing config: ADD files I don't have. For any file that exists in
  both with different content, show me a short summary of the differences
  and ask per file (or batched by type): keep mine / take repo's / merge.
- NEVER overwrite or delete: steering/personal-*.md, agents/personal-*,
  agents/accounting.*, prompts/accounting.md, or local runtime state
  (logs/, sessions/, workspace-roots/).
  For settings/cli.json, merge in missing keys only — keep my existing
  values.
- Ask me questions whenever a merge decision isn't obvious.

STEP 3 — Install prerequisites: read the "Local Tooling Required by MCP
Servers" table in README.md and install anything missing (uv/uvx, node/npx,
awscli, awsdac, ruff, prettier, shfmt, git-delta; swiftformat if on macOS
and iOS work is planned). If import.sh exists, prefer running it.

STEP 4 — Validate:
- Run ./validate.sh — it must print "All checks passed. Safe to push."
- Run `kiro-cli agent list` — expect all agents listed with master as
  default and NO warnings

STEP 5 — MCP servers: for any MCP server that requires an API key
(GITHUB_PERSONAL_ACCESS_TOKEN, TWENTY_FIRST_API_KEY, FIGMA_API_KEY), check
if the key exists on my machine. If missing, ask me for it; if I decline,
remove that MCP server from the agent's config. The google-workspace agent
needs a local Google OAuth file
(~/.config/google-drive-mcp/gcp-oauth.keys.json) — if absent, leave the
agent installed but tell me it won't connect until I set that up.

STEP 6 — Research current state: check the Kiro changelogs
(https://kiro.dev/changelog/cli/ and /ide/ /models/ /general/) for anything
newer than what steering/AGENTS.md documents, and the Agent Toolkit for AWS
(https://aws.amazon.com/products/developer-tools/agent-toolkit-for-aws/)
for new capabilities. Propose (don't auto-apply) updates for anything new.

Finally, clean up the temp clone and report: what was merged vs kept vs
skipped, agents working, any MCP servers disabled and why, and anything
that needs my attention.
```

</details>

<details>
<summary><strong>📦 Manual Installation</strong></summary>

<br>

```bash
# Clone directly into your Kiro config directory
git clone https://github.com/seandkendall/kiro-config.git ~/.kiro

# Or clone elsewhere and copy over
git clone https://github.com/seandkendall/kiro-config.git
cp -r kiro-config/{agents,steering,skills,prompts,settings,hooks} ~/.kiro/
```

</details>

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed (latest tested with **2.13.0**)
- Python 3.14+ with `uv` and `uvx`
- Node.js 24+ with `npx`
- AWS CLI v2 configured with named profiles
- Git

## Local Tooling Required by MCP Servers

Several MCP servers shell out to local tools. **If you're using an AI coding agent to set this config up automatically, the agent must install everything below before any MCP server will work.** The included `import.sh` handles all of this on macOS.

| Tool                                         | Install (macOS)                                                                                   | Install (Linux)                                                                           | Used by                                                                                                                        |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Homebrew**                                 | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | n/a — use distro package manager                                                          | Mac base                                                                                                                       |
| **`uv` / `uvx`**                             | `curl -LsSf https://astral.sh/uv/install.sh \| sh`                                                | same                                                                                      | All `uvx` MCP servers (AWS toolkit, DuckDuckGo, etc.)                                                                          |
| **`node` / `npx`**                           | `brew install node`                                                                               | `apt install nodejs npm` (or nvm)                                                         | Context7, GitHub, Playwright, shadcn, 21st.dev, Figma, Browser Lens, Sequential Thinking, Fetch, Chrome DevTools, Google Drive |
| **AWS CLI v2**                               | `brew install awscli`                                                                             | [AWS docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | All AWS-flavored agents (configured profiles required)                                                                         |
| **`awsdac`**                                 | `brew install awsdac`                                                                             | `go install github.com/awslabs/diagram-as-code/cmd/awsdac@latest`                         | `aws-diagram-png` skill (PNG architecture diagrams with real AWS icons)                                                        |
| **Playwright browsers**                      | `npx playwright install --with-deps chromium firefox webkit`                                      | same                                                                                      | `@playwright/mcp` server (E2E testing, browser automation) on `frontend`, `testing`, `web-builder` agents                      |
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

## What's Included

### Agents (22)

| Agent              | Description                                                                                                          |
| ------------------ | -------------------------------------------------------------------------------------------------------------------- |
| `master`           | Orchestrator — routes to the right specialist subagent                                                               |
| `master-demo`      | Single-agent demo for serverless backend builds — only `aws-mcp-server`, no subagents, CORS-aware, no UI/WAF/Route53 |
| `serverless`       | AWS Lambda, API Gateway, DynamoDB, Step Functions, Powertools                                                        |
| `frontend`         | React, TypeScript, Tailwind CSS, shadcn/ui, Playwright, Figma                                                        |
| `testing`          | pytest, Jest/Vitest, Playwright E2E via subagent                                                                     |
| `architect`        | Architecture diagrams, cost estimation, Well-Architected reviews                                                     |
| `ai-builder`       | Amazon Bedrock, Strands Agents, prompt engineering, RAG, AgentCore (full agentic apps)                               |
| `devops`           | CloudWatch monitoring, alerting, cost optimization                                                                   |
| `data`             | DynamoDB single-table design, data modeling                                                                          |
| `security`         | IAM, encryption, cdk-nag, CloudTrail                                                                                 |
| `docs`             | READMEs, API docs, ADRs, runbooks                                                                                    |
| `image-gen`        | Image generation via Bedrock (Nova Canvas + SD 3.5)                                                                  |
| `research`         | Deep research with web search, AWS docs, GitHub                                                                      |
| `web-builder`      | React + AWS full-stack web apps; delegates AI features to `ai-builder`                                               |
| `ios`              | Native iOS: Swift, SwiftUI, CarPlay, MapKit, AVFoundation, MusicKit, CoreLocation, offline-first MVVM                |
| `ios-testing`      | iOS tests: XCTest, XCUITest, swift-snapshot-testing, performance tests, protocol-based mocking                       |
| `ring`             | Amazon Ring integrations: Ring App Store apps + device APIs, events/webhooks (official Ring MCP)                     |
| `google-workspace` | Google Docs, Sheets, Drive (read-only)                                                                               |
| `stocks`           | Stock trading research and analysis (Yahoo Finance MCP)                                                              |
| `shopify`          | Shopify + AWS serverless integration builder (Shopify dev MCP)                                                       |
| `reinvent`         | AWS serverless backend builder — SAM-first (Lambda, API GW, DynamoDB)                                                |
| `promptgen`        | Generates agentic prompts for full-stack AWS application builds                                                      |

### Steering Docs (26)

Rules and standards automatically loaded into every session: accessibility, API design, AWS/CDK patterns, AWS Agent Toolkit usage, change logging, development workflow, error handling, no-CI/CD, performance, Python standards, security policies, iOS (Swift/SwiftUI, CarPlay, audio, offline-first — loaded on Swift files), and more.

> **Personal steering** — say "always …" / "from now on …" / "I prefer …" or repeat a preference 2+ times in a session, and the agent will offer to save it as a `personal-<topic>.md` steering doc on your machine. These files are gitignored and ALWAYS win over base rules. No extra tooling required — they just work via Kiro's existing steering loader. See `steering/personal-rules-protocol.md` and `skills/personal-rules-management.md`.

### Skills (16)

| Source                | Skills                                                                                                                                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Custom (11)           | AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, deploy-on-aws, AWS architecture diagrams (draw.io XML), AWS diagram PNG (awsdac), personal rules management, email template rendering, Cognito email migration, Cypress-to-Playwright migration |
| AWS Agent Toolkit (2) | Amazon Bedrock (incl. AgentCore), MCP tool discovery — the other 14 vendored toolkit skills were retired 2026-07-21; the managed AWS MCP Server now serves them on demand via `aws___retrieve_skill` / Agent SOPs (see `skills/AWS-TOOLKIT-SKILLS-AUDIT.md`)                   |
| iOS reference (3)     | Amazon Location Service, Amazon Polly generative voices, Cognito passkey auth (loaded by the `ios` agent)                                                                                                                                                                      |

### MCP Servers

Agents configure their own MCP servers. Key servers used across agents:

| Server              | Agents                                                     | Purpose                              |
| ------------------- | ---------------------------------------------------------- | ------------------------------------ |
| AWS MCP Server      | All 15 agents                                              | Full AWS API, docs, skills, scripts  |
| Context7            | frontend, serverless, architect, data, web-builder, master | Live library docs (React, AWS, etc.) |
| Playwright          | frontend                                                   | Browser automation and E2E testing   |
| shadcn              | frontend, web-builder                                      | Component registry browsing/install  |
| 21st.dev Magic      | frontend, web-builder                                      | AI UI generation from descriptions   |
| Figma Framelink     | frontend                                                   | Design-to-code from Figma URLs       |
| Browser Lens        | frontend, web-builder                                      | Live CSS/layout debugging            |
| Sequential Thinking | master, frontend                                           | Structured reasoning chains          |
| DuckDuckGo          | master, research + 3                                       | Privacy-first web search             |
| GitHub              | master, research, devops + 1                               | GitHub API (repos, PRs, issues)      |
| Chrome DevTools     | frontend, web-builder, testing                             | Chrome debugging                     |
| Bedrock Image       | master, image-gen, frontend, web-builder, ai-builder       | Image generation                     |
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

### Google Workspace agent (optional, local-only setup)

The `google-workspace` subagent (reachable from `master`) uses a Google Drive MCP server that requires a **local Google OAuth client-secrets file**. It is **not** part of this repo and most users will not have it — that subagent simply won't connect until you set it up, while every other agent works normally.

To enable it:

1. Create a Google Cloud OAuth client (Desktop app) and download its credentials JSON.
2. Save it to `~/.config/google-drive-mcp/gcp-oauth.keys.json` (the path the `google-workspace` agent expects via `GOOGLE_DRIVE_OAUTH_CREDENTIALS`).
3. Restart Kiro CLI; the agent runs read-only (`drive.readonly` scope).

This file is a credential — keep it out of version control (it is gitignored here as `gcp-oauth.keys.json`).

## Configuration

The default model and settings are in `settings/cli.json`. Key settings:

- `chat.defaultAgent`: `master` (the orchestrator)
- `chat.defaultModel`: `claude-opus-5`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`
- `chat.greeting.enabled`: `true`
- `toolSearch.enabled`: `true`

> **First-time setup tip** — Kiro CLI silently mutates `settings/cli.json` between sessions (e.g., it can flip `chat.greeting.enabled`). When `validate.sh` runs before a push, Step 5 surfaces any uncommitted settings drift so you can confirm or revert before it sneaks into a commit. Prefer `git add <specific-file>` over `git add -A` for narrow changes — see `steering/development-workflow.md` ("Settings Change Confirmation" rule).

## Key Conventions

- **CDK in Python only** — never TypeScript for infrastructure
- **TypeScript for React frontends only**
- **deploy.sh is the only deployment method** — no CI/CD pipelines, no git hooks
- **Kiro Specs before code** — requirements.md → design.md → tasks.md
- **10+ recommendations** after every completed task
- **cdk-nag** for security validation on all stacks
- **Lambda Powertools** (Logger, Tracer, Metrics) on all Lambda functions
- **MCP-over-CLI** — github MCP for github.com operations (never `gh`); `aws-mcp-server` for AWS (never bare `aws` CLI)

## Troubleshooting

Common install issues:

| Symptom                                                     | Likely cause                                                           | Fix                                                                                                                          |
| ----------------------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Agent fails to call AWS APIs ("could not load credentials") | No AWS profile configured                                              | Run `aws configure --profile <name>`. Most AWS-flavored agents look up credentials from a named profile, not env vars.       |
| MCP server fails at startup with "API key not set"          | Missing env var in `~/.zshrc`                                          | Re-run `./import.sh` — it prompts for each missing key. Or set the variable manually and `source ~/.zshrc`.                  |
| First run of a `uvx`/`npx` MCP server times out             | Package is downloading on first invocation                             | The config sets `mcp.noInteractiveTimeout` to 180s. If it still times out, run `uvx <pkg>` once manually to warm the cache.  |
| `import.sh` fails on Linux                                  | Some install lines use `brew` (macOS-specific)                         | Adapt the Linux equivalents from the Local Tooling table above (`apt install ...` instead of `brew install ...`).            |
| Agent silently fails to delegate                            | Custom orchestrator agent doesn't have `subagent` in its `tools` array | Add `"subagent"` to the agent's `tools` array, or use `"tools": ["*"]` / `"@builtin"`. See `steering/AGENTS.md`.             |
| `kiro-cli mcp list` shows no servers                        | Tool name collision with Kiro CLI's deferred tools                     | Rename the colliding MCP server key (e.g., `sequential-thinking` → `sequentialthinking`). See `steering/troubleshooting.md`. |

For deeper Kiro CLI issues (settings not loading, side channels in deploy.sh, agent validation errors), see `steering/kiro-cli-troubleshooting.md`.

## License

Apache License 2.0 — see [LICENSE](LICENSE). Shared publicly for reference and reuse. See [CONTRIBUTING.md](CONTRIBUTING.md) for the pre-push validation flow and contribution guidelines.
