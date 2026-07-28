# Changes

A chronological log of change-sets made to this project. Each round is one set of
changes recorded before handing back to the user. Newest rounds are appended to the bottom.

## Round 1 — 2026-06-16 18:25:28 -04:00

- Added `steering/change-logging.md` — new `inclusion: always` steering doc mandating a per-project `CHANGES.md` with round-numbered, timestamped, GitHub-friendly entries
- Updated `README.md` — bumped always-loaded steering doc count 16 → 17 (intro + "Steering Docs" header) and added "change logging" to the topics list
- Updated `CHANGELOG.md` — added `[0.15.0]` entry documenting the new steering rule
- Added this `CHANGES.md` file at the repo root and recorded `Round 1`

## Round 2 — 2026-06-23 11:00:08 -06:00

- Fixed image generation being unreachable from `master`: added `bedrock-image-mcp-server` to `agents/master.json` `mcpServers` (on-demand via Tool Search)
- Added `"AWS_REGION": "us-east-1"` to the `bedrock-image-mcp-server` env in `agents/image-gen.json`, `frontend.json`, `web-builder.json`, and `ai-builder.json`
- Updated `prompts/master.md` — image-generation workflow now covers direct tool use plus `image-gen` delegation
- Updated `agents/master.json` welcome message to mention image generation
- Updated `README.md` — corrected the Bedrock Image MCP server agent list
- Added `[0.16.0]` entry to `CHANGELOG.md`; verified the MCP server exposes 20 tools via a live stdio handshake and `./validate.sh` passed

## Round 3 — 2026-06-23 21:06:37 -06:00

- Added a "Kiro CLI V3 (Early Access) — Readiness" section + `permissions.yaml` note to `steering/AGENTS.md`
- Bumped Kiro CLI version refs 2.7.0 → 2.8.0 across `README.md`, `steering/AGENTS.md`, `steering/tech.md`, `steering/kiro-cli-troubleshooting.md`
- Updated `prompts/ai-builder.md` for AgentCore managed-harness GA (CLI + Guardrails-in-Policy) and Strands 1.0 patterns (Agents-as-Tools/Swarm/Graph/Workflow, A2A, Shell, Evals 1.0); added a harness note to `skills/amazon-bedrock/SKILL.md`
- Added a V3-aware explanation for `settings/permissions.yaml` in `.gitignore` (gitignored permanently)
- Added `skills/AWS-TOOLKIT-SKILLS-AUDIT.md` marking 15 vendored awslabs skills as trim candidates (no deletion)
- Bumped CDK alpha-module note to 2.260 in `steering/aws-standards.md` (verified both modules still alpha)
- Added `steering/kiro-cli-v3-migration.md` (manual inclusion) with the full v2→v3 mapping + checklist
- Added draft `agents/v3-preview/master.md` + `README.md` (V3 Markdown prototype, not loaded by 2.x)
- Added `[0.17.0]` to `CHANGELOG.md`; `./validate.sh` passed (all 20 agents validate, safe to push)

## Round 4 — 2026-06-23 21:37:46 -06:00

- Refreshed all dependency pins in `skills/package.json.template` to latest (React 19.2.7, React Router 7.18.0, Zod 4.4.3, Tailwind 4.3.1, Vite 8.1.0, TypeScript 6.0.3, Vitest 4.1.9, ESLint 10.5.0, Playwright 1.61.1, etc.); bumped `engines.node` to `>=24`; removed invalid `premailer` npm dep; added a major-upgrade caveat comment
- Updated "React 18+" → "React 19+" in `steering/tech.md` (frontmatter + list) and `skills/react-frontend-patterns.md` frontmatter
- Updated `README.md` prerequisite "Node.js 20+" → "Node.js 24+" (latest LTS)
- Updated pinned `boto3==1.35.0` → `boto3==1.43.36` in `skills/cognito-email-migration.md`
- Verified latest versions against npm/PyPI/Node release index; left Python 3.14, boto3 minimum-floor docs, AWS-fact runtime lists, and historical entries unchanged; `./validate.sh` passed

## Round 5 — 2026-06-25 11:28:00 -06:00

- Added `google-workspace` to `prompts/master.md` AVAILABLE SUBAGENTS + a COMMON WORKFLOWS routing line, with a note to fall back gracefully when the local Google OAuth file is absent (master.json already permitted it; the prompt was the missing link)
- Added a "Google Workspace agent (optional, local-only setup)" section to `README.md` documenting the `~/.config/google-drive-mcp/gcp-oauth.keys.json` requirement
- Added a `.gitignore` guard for `gcp-oauth.keys.json` (Google OAuth client secret)
- Added `[0.19.0]` to `CHANGELOG.md`; `./validate.sh` passed

## Round 6 — 2026-06-28 18:36:59 -06:00

- Reversed the secrets default in `steering/security-policies.md`: prefer SSM Parameter Store (`SecureString`) by default; Secrets Manager only when required (RDS/Aurora, service needs a secret ARN, rotation, cross-account) — section body + frontmatter updated
- Aligned the "No Hardcoded Values" rule in `steering/aws-standards.md` with the SSM-preferred guidance
- Left Secrets-Manager-required skill references (MSK/MQ/RDS Data API/AgentCore) unchanged — those are the documented exceptions
- Added `[0.20.0]` to `CHANGELOG.md`

## Round 7 — 2026-06-30 11:51:49 -06:00

- Replaced AppRegistry/myApplications guidance in `steering/aws-standards.md` with AWS Resource Groups (stable `aws_resourcegroups.CfnGroup`, tag-based on `project`); rationale: AWS moved AppRegistry + myApplications to maintenance (2026-07-30)
- Added a NON-DESTRUCTIVE myApplications→Resource Groups migration procedure (preserve Lambda/CW logs/S3/databases; only remove the AppRegistry Application + optional `awsApplication` tag; never `cdk destroy`)
- Removed `aws_servicecatalogappregistry_alpha` from the still-alpha note; fixed frontmatter; switched deploy.sh deep-cleanup + multi-project discovery to the `project` tag
- Added a tag-based `CfnGroup` snippet to `skills/cdk-infrastructure-patterns.md`
- Updated `prompts/master-demo.md` + `agents/master-demo.json` NEVER lists (AppRegistry → resource grouping/Resource Groups)
- Bumped Kiro refs 2.8.0 → 2.10.0 (README, AGENTS, tech, troubleshooting) + added 2.9.0/2.10.0 feature bullets (V3 stability/Entra ID; Config Hot-Reload + `chat.disableInheritingDefaultResources`)
- Added `[0.21.0]` to `CHANGELOG.md`; `./validate.sh` passed

## Round 8 — 2026-06-30 12:14:24 -06:00

- Added a "Construct Level (MANDATORY) — prefer L2/L3 over L1" rule to `steering/aws-standards.md`: when guidance reaches for an L1 `Cfn*`, verify whether `aws-cdk-lib` now has an L2/L3 and propose it instead; fall back to L1 only when none exists; re-check on each CDK upgrade
- Added the same rule to `skills/cdk-infrastructure-patterns.md` Rules + an L1 note on the `CfnGroup` snippet (no L2 for Resource Groups as of CDK 2.260)
- Added `[0.22.0]` to `CHANGELOG.md`; `./validate.sh` passed

## Round 9 — 2026-07-18 12:13:06 -06:00

- Root-caused why `kiro-cli chat --v3` wasn't working: 13 agents had `tools: [*]` (invalid YAML bare-star alias) — fixed to `tools: ["*"]`; all 17 agents now parse
- Corrected `steering/kiro-cli-v3-migration.md` (it recommended the bad `tools: [*]`); added correct invocation + validation guidance + backup location
- Rewrote `validate.sh` Step 1 to validate V3 Markdown agent frontmatter (was a no-op after the JSON→.md move); extended Step 2 (hooks + v2-backup JSON) and the privacy guard (.md personal/accounting agents)
- `.gitignore`: ignore `agents/personal-*.md` + `agents/accounting.md`
- Bumped Kiro 2.10 → 2.13 (README/AGENTS/tech/troubleshooting) + 2.11/2.12/2.13 feature notes; AGENTS.md reflects completed V3 migration
- Added a V3-not-loading troubleshooting entry; added `ios`/`ios-testing` to the README agent table
- Validated iOS agents + 4 iOS steering docs (parse + best practices, no shortcut conflicts)
- Added `[0.23.0]` to `CHANGELOG.md`; `./validate.sh` passes (17 V3 agents)

## Round 10 — 2026-07-18 13:20:03 -06:00

- Found (via `~/.kiro/logs`) the real reason agents didn't show in V3: `permissions:` was a bare array but V3 wants an object with `rules:` — rewrapped all 17 agents; verified all 17 now register (`[ProfileLoader] Registered user profile`)
- Removed redundant `agents/v3-preview/`; quoted unquoted-colon `description:` in steering docs (V3 was rejecting them); added frontmatter to 3 iOS skills (location/polly/cognito-passkey)
- Hardened `validate.sh` to reject non-object `permissions`; updated `steering/kiro-cli-v3-migration.md` with both root-cause bugs
- Re-verified via V3 startup logs: 0 agent parse failures, 0 steering frontmatter errors, 0 skill warnings, 17 profiles registered

## Round 11 — 2026-07-19 18:40:55 -06:00

- Built the `ring` Amazon Ring integration subagent in both engines: `agents/ring.md` (V3), `agents/v2-backup/ring.json` (V2), `prompts/ring.md`
- Wired the required remote MCP `ring-appstore-knowledge-mcp-server` (`type: streamable-http`) into the agent; added context7/github/aws-mcp-server
- Wired `ring` into master (V3 AVAILABLE SUBAGENTS + COMMON WORKFLOWS; V2 availableAgents/trustedAgents) with count bumps
- Added `ring` to the README agent table (18 agents)
- Verified: V3 registers 18 profiles incl. `ring`, 0 parse failures; V2 `ring.json` passes `kiro-cli agent validate`; `./validate.sh` → validated 18 V3 agents, safe to push
- Added `[0.24.0]` to `CHANGELOG.md`

## Round 12 — 2026-07-20 10:30:16 -06:00

- Investigated the V3 `reasoning`/`additionalModelRequestFields` error via `~/.kiro/logs`: root cause is the active model being switched to `gpt-5.6-sol` (2286 reqs) which doesn't accept the `reasoning` field while `chat.enableThinking:true` sends it — a model↔thinking mismatch (likely a Kiro V3 bug), not a config defect
- Catalogued other log errors (web_search no-results ×19, large-context stream failures ~1MB, relative-path tool calls, transient Bedrock InternalServerException/resets, local creds-agent MCP disconnect) — all transient or model-behavior, not config
- Added a "Kiro CLI V3 Runtime Errors" section to `steering/kiro-cli-troubleshooting.md` with causes + fixes; `[0.24.1]` in `CHANGELOG.md`

## Round 13 — 2026-07-20 10:55:56 -06:00

- Investigated the `InternalServerException` (session sess_29ca82b6): transient server-side retryable Bedrock error on a ~772 KB / 142-history-message payload (model gpt-5.6-sol) — not a config defect
- Identified a config contributor: agents list `file://~/.kiro/steering/*.md` in `resources` while V3 ≥2.7 also auto-inherits default steering → likely double-loading, inflating payloads (log shows repeated AGENTS.md steering re-population)
- Enhanced the troubleshooting `InternalServerException` entry with the large-payload correlation + `chat.disableInheritingDefaultResources` de-dupe mitigation (no settings/agent change made — pending owner approval)

## Round 14 — 2026-07-20 20:38:59 -06:00

- Made V2 and V3 work simultaneously: copied the 18 active agents' `.json` to top-level `agents/` alongside the `.md`. Verified V2 `agent list` shows all 18 and V3 registers all 18 (0 parse failures, 0 conflicts — V3 ignores `.json`)
- Fixed V2 duplicate shortcut: `agents/ios-testing.json` ctrl+9 → shift+t
- `.gitignore` + `validate.sh` privacy guard now cover `agents/v2-backup/{accounting,personal-*}`; Step 2 JSON check now includes top-level `agents/*.json`
- Documented the side-by-side layout in `steering/kiro-cli-v3-migration.md`; `[0.25.0]` in `CHANGELOG.md`; `./validate.sh` passes

## Round 15 — 2026-07-21 06:44:55 -06:00

- Final full validation: `./validate.sh` all green; V2 `agent list` = 18 agents, no warnings; V3 startup = 18 registered, 0 parse failures; `.json`/`.md` curated sets identical; Ring agent present in both with the correct MCP URL and registered in V3
- Found + gitignored an externally-managed ACP agent (`agents/quickwork_acp_kiro.json`, "QuickWork managed agent") — machine-specific, would have leaked; added `agents/*_acp_*.json` to `.gitignore` (confirmed `git check-ignore`)

## Round 16 — 2026-07-21 13:17:01 -06:00

- Deep review against latest docs (CLI changelog + V3 agent-config/hooks pages): 2.13.0 confirmed latest public; agent schema fully compliant
- Fixed `hooks/formatters.json` — was `PostToolUse`/`fs_write` + V2 `$FILEPATH` (unset in V3 → silent no-op); rewrote to documented `PostFileSave` + extension matchers + `{{filePath}}` + timeouts; updated migration doc
- Re-verified: hooks JSON valid (v1, 4 hooks), `./validate.sh` green, V3 = 18 registered / 0 failures / 0 hook errors; `[0.25.1]` in `CHANGELOG.md`

## Round 17 — 2026-07-21 13:43:54 -06:00

- Rewrote the README "Quick Install Using Your AI Agent" prompt for the dual-format era: 5 explicit steps — prerequisites, verify BOTH V2 (`agents/*.json`) and V3 (`agents/*.md`) sets + `hooks/formatters.json`, validate both engines (`./validate.sh`, V2 `agent list`, V3 log check for Registered/Failed-to-parse) incl. the two known V3 pitfalls, MCP key handling that keeps `.json`+`.md` in sync, and propose-only changelog/toolkit research
- Fixed the Manual Installation `cp` line to include `hooks/`
- `[0.25.2]` in `CHANGELOG.md`

## Round 18 — 2026-07-21 20:30:44 -06:00

- Context de-dupe across all 18 V3 agents: `resources` trimmed to `file://README.md` (steering/skills/AGENTS.md are auto-inherited; the explicit glob double-loaded steering and defeated `fileMatch`/`auto` inclusion modes)
- Least-privilege `tools` tags per agent role (orchestrators keep full set; research/google-workspace heavily trimmed; delegating builders keep `subagent`)
- Added `timeout: 180000` to every stdio MCP server in the `.md` agents (first-run uvx/npx downloads exceed V3's 60s default)
- Removed hardcoded "(N available)" counts from welcome messages
- Created `sync-agents.py` — V3 `.md` canonical; regenerates V2 `.json` + `prompts/*.md`; `--check` parity mode wired into `validate.sh` as Step 1.5
- Created `hooks/guardrails.json` — PreToolUse destructive-shell agent guardrail + Manual `log-changes-round` hook
- Removed machine-local `creds-agent` MCP + `@creds-agent` tool refs from `agents/master.json`
- Updated README AI tips + install prompt and the migration doc for the canonical-`.md`/sync workflow
- Verified: validate.sh all green incl. new parity step; V2 `agent list` no warnings + all 18 JSON pass `kiro-cli agent validate`; V3 startup 18 registered / 0 failures / 0 hook errors; `[0.26.0]` in `CHANGELOG.md`

## Round 19 — 2026-07-21 21:18:06 -06:00

- Investigated the missing `stocks`/`shopify`/`reinvent`/`promptgen` agents: accidentally dropped in the Jul-18 V3 migration (moved to v2-backup, never converted to .md); restored all 4 from git HEAD as V2-only agents
- Split `development-workflow.md` into a lean always-loaded core + new auto-loaded `steering/development-quality-gates.md`; demoted `structure.md` + `product.md` to `auto` (always-loaded steering context reduced)
- Deleted the 14 owner-approved vendored AWS toolkit skills (kept amazon-bedrock, mcp-tool-discovery, custom + iOS skills); marked the audit EXECUTED; updated README skills table (16) + intro counts + Steering Docs (22)
- Synced the stale README version line 0.10 → 0.27
- Added `tests/test_sync_agents.py` (4 tests, stdlib) + `KIRO_DIR` override in `sync-agents.py`; wired into `validate.sh` Step 3.5
- Added the V2 Retirement Plan (explicit GA trigger + 6-step sunset) to `steering/kiro-cli-v3-migration.md`
- Verified: self-test 4/4, validate.sh all green, V2 no warnings, V3 18/0/0; `[0.27.0]` in `CHANGELOG.md`

## Round 20 — 2026-07-22 11:46:03 -06:00

- Converted the 4 recovered legacy agents to V3: `agents/{stocks,shopify,reinvent,promptgen}.md` (delegator tags, trimmed resources, MCP timeouts, permissions.rules); ran `sync-agents.py` to regenerate their `.json`
- All 22 agents now dual-format: validate.sh → 22 V3 agents + parity + self-test green; V3 startup 22 registered / 0 failures (all 4 confirmed); V2 no warnings
- README: Agents (22) + 4 table rows + intro count; gitignored `agents/v2-backup/` entirely (machine-local backup)
- `[0.28.0]` in `CHANGELOG.md`; committing and pushing the full session (Rounds 9–20), excluding `settings/cli.json` CLI drift

## Round 21 — 2026-07-22 19:30:44 -06:00

- Untracked `models/` (86.9 MB Kiro embedding-model cache swept in by `git add -A`; GitHub flagged the 86 MB onnx file) and gitignored it — blob remains in history; rewrite offered but not performed

## Round 22 — 2026-07-27 18:19:55 -06:00

- Rewrote the README AI-led install: no manual clone — user just `cd ~/.kiro` + starts Kiro; agent clones to a temp dir (GitHub API fallback), then NON-DESTRUCTIVELY merges with any existing config (add-only, per-file questions on conflicts, never-touch list for personal/runtime files, cli.json merges missing keys only, git init for fresh setups, temp cleanup + merge report)
- `[0.28.1]` in `CHANGELOG.md`

## Round 23 — 2026-07-27 19:11:07 -06:00

- Moved the install blocks into a new `## Installation` section right after the README intro — AI-assisted install primary (open), Manual second, one-shot script remains a fallback under Local Tooling
- `[0.28.2]` in `CHANGELOG.md`
