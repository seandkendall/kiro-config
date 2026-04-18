# Changelog

All notable changes to this Kiro CLI configuration.

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
