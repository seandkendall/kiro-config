# Changelog

All notable changes to this Kiro CLI configuration.

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
