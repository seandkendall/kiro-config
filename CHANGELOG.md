# Changelog

All notable changes to this Kiro CLI configuration.

## [2026.05.15] - 2026-05-15

This release consolidates AI agents, locks down MCP-over-CLI usage across the board, adds a local pre-push validation script, and ships a reusable `mcp-tool-discovery` skill. Public-ready.

### Highlights

- **AI agents merged into one** — `agentcore` is gone; `ai-builder` now handles both AI integration patterns (model selection, prompts, RAG) AND full agentic app builds (Strands + AgentCore + Bedrock as default; SageMaker fallback only for custom models not on Bedrock).
- **Image agents merged into one** — `image-editor` is gone; `image-gen` now covers UI assets, marketing, virtual try-on, sketch-to-2D, and ambient art (Frame TV).
- **MCP-over-CLI rule** is now mandatory — every agent prompt instructs the agent to use the `github` MCP server for github.com operations, never `gh` CLI. Local git operations (`status`, `diff`, `log`, `add`, `commit`, `push`) still go through shell.
- **Lambda runtime** bumped from Python 3.13 to **Python 3.14** across every doc, prompt, and template (Lambda 3.14 GA was Nov 2025).
- **Pre-push validation** — new `./test-import.sh` runs export → simulated install → agent JSON validation → JSON/bash syntax. Catches schema drift and broken configs before they hit the public repo.
- **CI/CD and git hook bans** — `post-task-recommendations.md` now forbids both. The only deployment path is `deploy.sh`; the only validation path is `./test-import.sh`.

### New

- `skills/mcp-tool-discovery.md` — decision tree + cheat sheet for finding the right MCP tool when you're unsure
- `steering/kiro-cli-troubleshooting.md` — auto-loaded fix-it doc for missing tools, MCP failures, side-channel issues
- `skills/deploy.sh.template` — full deployment script using Kiro 2.3.0 side channels (`$AGENT_DISPLAY_OUT`, `$AGENT_CONTEXT_OUT`)
- `Documentation Sync` rule — agents must update `CHANGELOG.md` and `README.md` in the same commit as any change that affects them
- README "Tips for AI Agents" callout, GitHub badges, "Pre-push Checklist" section

### Removed

- `db` agent (Postgres DBA — not needed)
- `clean` agent (macOS disk cleanup — not needed)
- `agentcore` agent (merged into `ai-builder`)
- `image-editor` agent (merged into `image-gen`)
- Broken `fetch` MCP server (npm package didn't exist; built-in `web_fetch` covers it)

### Other

- `web-builder` orchestrator now delegates AI features to `ai-builder` (added to its trusted subagents list)
- `accounting` prompt sanitized to a generic Canadian SaaS template (Alberta-focused tax handling preserved)
- Steering descriptions added to 8 always-on docs so the auto-loader matches keywords reliably
- Privacy audit: no credentials, personal info, or business specifics in tracked files

## [2026.05.14] - 2026-05-14

### Added

- **awsdac PNG diagrams** — `aws-diagram-png` skill (uses `awslabs/diagram-as-code`) for direct PNG generation with real AWS icons. Complements `aws-architecture-diagram` (draw.io XML)
- **`deploy.sh.template`** — full deployment template under `skills/` with side-channel routing wired in
- **Agent output side channels** documented in `deploy-on-aws` skill (Kiro CLI 2.3.0): `$AGENT_DISPLAY_OUT` for verbose logs (TUI only), `$AGENT_CONTEXT_OUT` for facts (`agent_notes`)
- **`subagent` vs `delegate`** decision table added to `AGENTS.md`
- **Kiro CLI 2.3.0 features** documented in `tech.md` and `AGENTS.md`
- **`/code overview` onboarding guidance** in `development-workflow.md`
- **MCP smoke test** in `import.sh` runs `kiro-cli mcp list` after install
- **`kiro-cli-troubleshooting.md`** steering doc (auto-loaded) with common fixes
- **Local install guidance** in README explains what AI agents (Kiro, Cursor, etc.) must install autonomously

### Changed

- **Post-task recommendations** split into "for the user" (optional, omitted unless required) and "for the AI Agent" (mandatory, ≥10 items). Adds `Continue` interaction — type `Continue` to run all, or `Continue with 2, 5, 8` for a subset
- **`development-workflow.md`** response-format rule defers to `post-task-recommendations.md`
- **`import.sh` + `export-kiro.sh`** now copy non-`.md` files and recurse into skill subdirectories (toolkit skills are folders, `deploy.sh.template` was being missed)
- **`deploy-on-aws` skill** description matches "deploy.sh" requests
- **`aws-architecture-diagram` skill** cross-references `aws-diagram-png` (XML vs PNG)
- **Master welcome message** mentions diagram generation and deploy.sh
- **`aws-diagram-png` skill** uses base service types (e.g., `AWS::CloudFront`) instead of variants that trigger awsdac fallback warnings

### Fixed

- `BROWSER_LENS_API_KEY` removed from configs (Browser Lens MCP doesn't use it — was vestigial)
- `BRAVE_API_KEY` removed from `import.sh` (switched to DuckDuckGo)
- Stray `settings/mcp.json` removed (agents are self-contained)
- Skills directory was losing `deploy.sh.template` and toolkit subdirectories during export

## [2026.05.06] - 2026-05-06

### Added

- **AWS Agent Toolkit adopted** — `mcp-proxy-for-aws` (managed AWS MCP Server) added to all 18 agents
- **Google Workspace agent** — read-only Google Docs, Sheets, Drive access via `@piotr-agier/google-drive-mcp`
- **15 AWS toolkit skills** from `aws/agent-toolkit-for-aws`: Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless decision guide, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing/cost, CloudFormation, messaging/streaming
- **Steering doc** `aws-agent-toolkit.md` — prefer MCP server, discover skills before acting, verify docs
- `google-workspace` added as master subagent
- `import.sh`: Google Workspace setup guidance, BROWSER_LENS_API_KEY handling

### Removed

- `aws-documentation-mcp-server` from 15 agents (replaced by `aws___search_documentation`)
- `aws-serverless-mcp-server` from accounting, reinvent, serverless
- `aws-iac-mcp-server` from accounting, agentcore, shopify, web-builder, serverless, architect
- `aws-pricing-mcp-server`, `cost-explorer-mcp-server`, `billing-cost-management-mcp-server` from architect
- `awsknowledge` HTTP server from architect
- `postgres-mcp-server` from data and db agents (unused — no Postgres databases)

### Changed

- All agents now use single `aws-mcp-server` for AWS interactions (us-east-1)
- Skills count: 7 → 22 (7 custom + 15 from AWS Agent Toolkit)

## [2026.04.30] - 2026-04-30

### Added

- **Frontend agent supercharged** with 10 MCP servers: Playwright, shadcn, 21st.dev Magic, Figma Framelink, Browser Lens, Sequential Thinking, Fetch, Context7, Chrome DevTools, Bedrock Image
- **Context7** added to serverless, architect, data, and web-builder agents for live library docs
- **21st.dev Magic + shadcn** added to web-builder agent for AI UI generation and component registry
- **Sequential Thinking** added to master agent for structured reasoning
- **DuckDuckGo** replaced Brave as the web search MCP server across 7 agents (no API key needed)
- **No-duplicate-files rule** in `development-workflow.md` — always edit in-place, never create `file_new.py` or `file_v2.py`
- `TWENTY_FIRST_API_KEY` and `FIGMA_API_KEY` env var handling in `import.sh`
- Externalized frontend prompt to `prompts/frontend.md`

### Changed

- Default model upgraded from `claude-opus-4.6` to `claude-opus-4.7` (experimental preview, 1M context)
- `toolSearch.enabled` set to `true` (Kiro CLI v2.1 feature)

## [2026.04.18] - 2026-04-18

### Added

- **Daily Maintenance workflow** in `steering/development-workflow.md` — mandatory daily: upgrade all deps + research breaking changes, lint all source files, remove dead code, update README, verify builds
- **AWS AppRegistry guidance** in `steering/aws-standards.md` — every CDK app must register via `ApplicationAssociator` pattern (auto-associates all stacks, propagates `awsApplication` tag)
- Keyboard shortcuts for remaining agents: `shift+c` cypress, `shift+d` data, `shift+o` docs, `shift+i` image-gen, `shift+s` security
- `LICENSE` (Apache-2.0)
- `What's New` section in README
- Git tag `v2026.04.18`

### Removed

- `blazor` agent and prompt (was temporary for a friend)
- "Microsoft Learn" reference from aws-standards.md

## [2026.04.10a] - 2026-04-10

### Added

- PostToolUse formatting hooks: `ruff` (Python), `prettier` (TS/HTML/CSS), `shfmt` (bash)
- `shell.autoAllowReadonly` on 17 agents — read-only commands don't prompt
- `aws.autoAllowReadonly` on 8 agents — read-only AWS CLI calls don't prompt
- `web_fetch.trusted` patterns for AWS docs and GitHub on 17 agents
- Keyboard shortcuts: ctrl+2 research, ctrl+8 architect, ctrl+9 devops, ctrl+0 ai-builder
- `deploy-on-aws` skill with awsknowledge, awsiac, awspricing MCP servers
- `aws-architecture-diagram` skill (replaces deprecated aws-diagram-mcp-server)
- `import.sh` installer script with Kiro CLI auto-install option
- `export-kiro.sh` for shareable exports
- `.gitignore` for sessions, extensions, powers, credentials
- Pre-push git hook to run export before every push
- `CHANGELOG.md`
- `README.md` with prerequisites, agent table, and setup instructions
- `chat.diffTool` set to `delta` for syntax-highlighted diffs

### Changed

- Externalized 11 long inline prompts to `file://` URIs in `prompts/`
- Standardized all prompt URIs to `file://./prompts/` format
- Replaced `toolsSettings.execute_bash` → `shell` across all agents
- Replaced `toolsSettings.fs_write` → `write` across all agents
- Converted `autoApprove` MCP server fields to `allowedTools` entries
- Updated devops agent: removed CI/CD focus, now monitoring/alerting/cost only
- Updated master prompt: removed gaming redirect, streamlined workflows

### Removed

- Gaming agents: `unity.json`, `godot.json`, `master-gaming.json`
- Gaming skill: `unity-fps-best-practices.md`
- Gaming prompt: `master-gaming.md`
- Gaming MCP server: `godot-mcp/`
- Gaming script: `unity-build-loop.sh`
- Nova Act MCP server and all references
- `mcp-server-fetch` from 9 agents (built-in `web_fetch` since v1.21)
- `useLegacyMcpJson` field from all agents
- `$schema` field from all agents
- `backup_on_overwrite` from all agents
- `search` → `web-search` toolAliases (built-in `web_search` since v1.21)
- `model: null` from all agents
- `agent_config.json.example`
- `elevenlabskey.txt`
- `steering-backup-Dec42025/`
- Empty `scripts/` directory
- Global `mcp.json` (agents are self-contained)
- Deprecated MCP servers: `code-doc-gen`, `aws-diagram`, `core-mcp-server`

### Fixed

- CI/CD references removed from all agents and steering (strict ban in `post-task-recommendations.md`)
- All agent configs now conform to latest Kiro CLI schema (v1.29)
- All prompt `file://` URIs verified to resolve correctly in exports

## [2026.04.09] - 2026-04-09

### Added

- Initial versioned export
- Post-task recommendations steering doc (mandatory 10+ items after every task)
- CI/CD ban rule across all agents and steering

### Changed

- Global model set to `claude-opus-4.6`
