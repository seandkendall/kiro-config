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

## Round 24 — 2026-07-28 -06:00

- Made `reinvent` AWS-SAM-only per user request: removed all CDK mentions from `prompts/reinvent.md` (previously "SAM or AWS CDK" / "CDK when appropriate") — AWS SAM is now the agent's sole, non-negotiable IaC tool
- Added Lambda Durable Functions and Amazon Bedrock integration to `prompts/reinvent.md`'s expertise list (previously undocumented despite being implied by the agent's description)
- Added a `SKILLS:` section to `prompts/reinvent.md` directing the agent to retrieve the AWS Agent Toolkit's `aws-serverless` (core) and `aws-lambda-durable-functions` (specialized) skills on demand via `aws___retrieve_skill`, confirmed via research since no standalone "AWS SAM" skill exists in the toolkit catalog — SAM guidance lives inside the `aws-serverless` core skill
- Corrected mid-task error: initially overwrote `prompts/reinvent.md` and `agents/reinvent.json` based on a stale context summary that incorrectly claimed the agent has no subagents; re-diffed against git HEAD, found real content (subagent delegation paragraph, `../steering/*.md` resource, Well-Architected framing) and restored it, applying only the SAM-only + skills changes on top instead of a full rewrite
- Updated `agents/reinvent.json` description and `README.md` agent table row to reflect AWS SAM only (previously "with SAM" / "SAM-first", implying CDK was still an option)
- Verified `./validate.sh` green (33 agents validate, JSON/bash syntax OK, no Cypress regressions); confirmed `settings/cli.json` trailing-newline drift is pre-existing CLI noise, not staged

## Round 25 — 2026-07-28 -06:00

- Confirmed exact skill names authoritatively via the AWS MCP Server (fully-qualified `mcp_aws_mcp_server_aws___*` invocation, working around the bare `aws___*` alias being unreachable this session): `aws-serverless` (core skill, description explicitly names SAM/CDK/SAM templates) and `aws-lambda-durable-functions` (specialized serverless skill) — both retrieved and their SKILL.md content verified, superseding last round's web-search-only confirmation
- Added a routing rule to `prompts/reinvent.md`'s `SKILLS:` section: when a user requests orchestration/workflow coordination without naming a technology, the agent must surface the Step Functions vs. Lambda Durable Functions choice rather than silently picking one — this is a rule the `aws-serverless` skill itself mandates, and `reinvent`'s heavy Durable Functions expertise made it a real risk of being silently defaulted
- Re-verified `./validate.sh` green after the prompt edit

## Round 26 — 2026-07-28 -06:00

- Trimmed `reinvent` to the user's exact real-world stack per explicit scope statement: React UI on S3/CloudFront, API Gateway, Lambda Durable Functions (all compute), DynamoDB, CloudWatch/X-Ray/OpenTelemetry observability, SAM for IaC and local testing
- Removed all Amazon Bedrock references (expertise bullet, `ai-builder` subagent delegation) — not part of this agent's stack
- Removed the Step Functions vs. Durable Functions routing rule added last round, and all EventBridge mentions — explicitly excluded by the user; added an explicit line telling the agent not to introduce services/tools outside the fixed stack without an explicit per-project request
- Added the previously-missing S3/CloudFront static hosting layer and AWS X-Ray to the expertise list — both were part of the user's stated stack but absent from the prompt
- Narrowed `SKILLS:` guidance to `aws-lambda-durable-functions` (primary) and `aws-serverless` (general serverless build/deploy/debug) — dropped Step Functions/Bedrock skill considerations
- Updated `agents/reinvent.json` description and `README.md` row to the trimmed stack description
- Verified `./validate.sh` green after the rewrite

## Round 27 — 2026-07-28 -06:00

- Made `reinvent` fully self-contained per explicit user request to get closer to `master-demo`: removed ALL subagent delegation (`frontend`, `data`, `testing`, `devops`, `security`, `docs`, `image-gen`) — the agent now builds the React UI, DynamoDB modeling, and everything else itself
- Root cause for cutting `frontend` too (not just testing/devops/security/docs/image-gen as literally requested): the `frontend` subagent has Playwright wired directly into its own MCP servers (`agents/frontend.json`), so keeping frontend delegation would have transitively reintroduced Playwright even after removing the `testing` subagent — flagged and cut both to honor "NO playwright guidance in this agent" fully
- Replaced the removed `devops` delegation with direct, mandatory prompt guidance: enable AWS X-Ray active tracing on every Lambda function and API Gateway stage, and integrate the ADOT Lambda layer into every function, on every build — no separate monitoring subagent
- Added an explicit `TESTING:` section banning Playwright/Cypress/E2E browser testing outright; verification is via curl / `sam local invoke` / `sam local start-api`
- Updated `agents/reinvent.json` description and `README.md` row to reflect "No subagents; X-Ray/ADOT observability built in"
- Verified `./validate.sh` green after the rewrite

## Round 28 — 2026-07-28 -06:00

- Removed all AWS X-Ray requirements from `reinvent` per user confirmation: the target account already pipes CloudWatch Logs to OpenObserve via Kinesis Data Firehose, and ADOT/OpenTelemetry exports traces+metrics directly via OTLP to OpenObserve — X-Ray would be a redundant, separately-billed tracing backend with no consumer in this setup
- Rewrote `OBSERVABILITY (MANDATORY)` section: mandatory OpenTelemetry via the ADOT Lambda layer on every function, exporting via OTLP to OpenObserve; explicit "do not enable X-Ray" with the reasoning inline; kept guidance to structure Lambda logs (structured JSON) so they flow cleanly through the existing CloudWatch → Firehose → OpenObserve pipeline
- Scrubbed remaining X-Ray mentions from the expertise list and `SUBAGENT DELEGATION` line (leftover text from the prior round); the only two remaining X-Ray mentions are the explicit "do not introduce/do not enable" exclusions, which are intentional
- Updated `agents/reinvent.json` description and `README.md` row to "OpenTelemetry/ADOT observability into OpenObserve, no X-Ray"
- Verified `./validate.sh` green after the rewrite

## Round 29 — 2026-07-28 -06:00

- Item 5: researched ADOT + Lambda Durable Functions IAM requirements via `aws___search_documentation` — AWS's own durable-execution SDK auto-instrumentation plugins (`ExecutionOtelPlugin`/`InvocationOtelPlugin`) rely on X-Ray's trace-ID propagation (`_X_AMZN_TRACE_ID`) and require `Tracing: Active` + `AWSXRayDaemonWriteAccess` purely for internal span plumbing — not for using X-Ray as a backend. Added an `IAM NOTE FOR DURABLE FUNCTIONS + OTEL` section to `prompts/reinvent.md` documenting this nuance and the alternative (manual `AWSOpenTelemetryDistro*` layer + plain OTLP exporter) that avoids the X-Ray IAM dependency entirely, rather than silently contradicting the prior round's "no X-Ray" mandate
- Item 6: found and fixed dangling `skill://` resource paths in `agents/master-demo.json`, `agents/serverless.json`, `agents/architect.json` — all referenced skill directories deleted in the 2026-07-21 toolkit-skills audit (`aws-serverless`, `connecting-lambda-to-api-gateway`, `connecting-lambda-to-dynamodb`, `debugging-lambda-timeouts`, `aws-messaging-and-streaming`, `routing-traffic-with-route53-and-cloudfront`, `aws-cloudformation`, `aws-billing-and-cost-management`) but never removed from the `resources` arrays; kept only entries pointing at files/directories confirmed still present on disk
- Item 7: deleted all 28 `agents/*.bak*` files (none tracked in git — confirmed via `git ls-files` before deleting)
- Item 4: re-ran `./validate.sh` after the full batch — 33 agents validate, JSON/bash syntax OK, no privacy leaks, no Cypress regressions, all green

## Round 30 — 2026-07-28 -06:00

- Added an `OTEL COLLECTOR CONFIG (SSM)` section to `prompts/reinvent.md` per user request: OpenObserve OTLP connection details resolved from SSM Parameter Store rather than hardcoded or asked-for-each-session — `/reinvent/otel/otlp-endpoint` (`String`, → `OTEL_EXPORTER_OTLP_ENDPOINT`), `/reinvent/otel/otlp-headers` (`SecureString`, → `OTEL_EXPORTER_OTLP_HEADERS`, resolved via `{{resolve:ssm-secure:...}}` in SAM templates, never printed/logged/hardcoded), `/reinvent/otel/org` (`String`, optional)
- Paths are flat/shared across all projects (`/reinvent/...`, no per-project namespace) per explicit user instruction — user will create these parameters in their own project's CDK/SSM setup
- Verified `./validate.sh` green after the addition

## Round 31 — 2026-07-28 -06:00

- Created `skills/openobserve-telemetry/SKILL.md` from the user's own account-verified instructions (`/Users/seandall/Downloads/PROJECTS/reinvent/reimburse/OpenObserve/docs/SENDING-TELEMETRY.md`): connection details (SSM-backed, not hardcoded), connectivity check, ADOT Lambda instrumentation, API Gateway trace continuity, log delivery options, naming/tagging, account-specific constraints (7-day retention, 24h late/future data rejection, sampling), a definition-of-done checklist, and troubleshooting steps
- Corrected a real error from earlier rounds: the source doc requires enabling `Tracing: Active` on API Gateway stages specifically for X-Ray's `X-Amzn-Trace-Id` header propagation — without it, API Gateway and Lambda traces split into two disconnected traces. This is NOT the same as using X-Ray as a viewing backend (still correctly excluded), but the prior "do not enable X-Ray" prompt language was too broad and would have broken trace continuity. Added an explicit `X-RAY:` section to `prompts/reinvent.md` distinguishing "no X-Ray backend/console" from "X-Ray propagation on API Gateway is required and non-optional"
- Corrected the SSM/endpoint shape to match the real, verified setup: base URL ends at `/api/default` (no signal path — SDK appends `/v1/traces` etc.), dedicated `otel-ingest` user (not root, `admin` role due to OSS-tier role restrictions) rather than an unspecified credential
- Rewrote `prompts/reinvent.md`'s `OBSERVABILITY`/`OTEL COLLECTOR CONFIG`/`IAM NOTE` sections to defer to the new skill as the authoritative source rather than duplicating/paraphrasing OTel setup details inline
- Wired `skill://~/.kiro/skills/openobserve-telemetry/SKILL.md` into `agents/reinvent.json`'s `resources` array
- Marked `openobserve-telemetry` as a permanent custom-skill "keep" in `skills/AWS-TOOLKIT-SKILLS-AUDIT.md` — it documents this account's own live OpenObserve deployment and can never be served by the AWS Agent Toolkit's managed registry
- Updated README skills table/count (16 → 17) and intro summary line
- Verified `./validate.sh` green after the full change

## Round 32 — 2026-07-28 -06:00

- User caught a real error: the invented `/reinvent/otel/otlp-endpoint`, `/reinvent/otel/otlp-headers`, `/reinvent/otel/org` SSM paths from earlier rounds were never in the source doc — confirmed by re-checking `SENDING-TELEMETRY.md` directly. Corrected `skills/openobserve-telemetry/SKILL.md` and `prompts/reinvent.md` to follow the doc exactly:
  - Only ONE SSM parameter: `/openobserve/otlp-basic-token` (`SecureString`) for the auth token
  - The OTLP endpoint is NOT stored in SSM at all — it's derived live from `aws cloudformation describe-stacks --stack-name OpenObserveEksDemoStack-us-east-1` each time, since the CloudFront domain can change and a cached SSM copy would risk going stale
  - Org (`default`) is a fixed constant baked into the API path, never a stored parameter
- Rewrote the skill's section 1 (connection details), section 2 (connectivity check script), and section 3.2 (Lambda env vars) to match; flagged that the exact stored-token format (raw token vs. full `Authorization=Basic <token>` string) needs confirming against what the user actually puts in the parameter
- Updated `prompts/reinvent.md`'s `OTEL COLLECTOR CONFIG` section to describe the single-parameter + live-CloudFormation-lookup pattern instead of the invented two-or-three-parameter scheme
- Verified `./validate.sh` green; confirmed no remaining `/reinvent/otel/...` references anywhere

## Round 33 — 2026-07-28 -06:00

- Added a `FRONTEND HOSTING (FIXED INFRASTRUCTURE — MANDATORY)` section to `prompts/reinvent.md`, scoped only to this agent per explicit instruction: every React project is hosted at the pre-existing CloudFront distribution `https://d5bldcvijpt3d.cloudfront.net/` backed by the existing S3 bucket `seandall-reinvent2026-website-hosting`; caching is off on that distribution. Never create a new `AWS::S3::Bucket` or `AWS::CloudFront::Distribution` for frontend hosting in a project's SAM template — reference the existing bucket instead. Deploy step is always `aws s3 sync ./build s3://seandall-reinvent2026-website-hosting --delete`, never `cp --recursive` or manual uploads
- Updated the top expertise bullet and "do not introduce other services" line to say "pre-existing CloudFront distribution (never a new one per project)"
- Explicitly noted this fixed-hosting rule applies only to `reinvent` — `serverless`/`web-builder` still create their own CloudFront distributions per project as normal
- Verified `./validate.sh` green


## Round 34 — 2026-07-28 -06:00

- Confirmed via `aws___search_documentation`/web search that AWS is retiring Amazon Nova Canvas: Legacy since 2026-03-30, full EOL 2026-09-30 — matches the deprecation notices already present in the `bedrock-image-mcp-server` tool descriptions (`generate_image`, `generate_image_with_colors` both marked DEPRECATED there)
- Removed all Nova Canvas guidance across the repo: `prompts/image-gen.md` (full rewrite — model table now maps to actual current tools: `generate_image_ultra`/`_sd35`/`_core` plus edit/upscale tools), `prompts/ai-builder.md`, `prompts/master.md`, `agents/image-gen.json` (description + welcomeMessage), `README.md`, `steering/AGENTS.md`
- Confirmed via AWS's official regional-availability docs that Stable Image Ultra, SD 3.5 Large, and Stable Image Core are `us-west-2`-only on Bedrock (no In-Region availability elsewhere); some editing/upscaling tools (`structure_control`, `upscale_conservative`/`_fast`, `sketch_to_image`) have wider availability (`us-east-1`/`us-east-2`/`us-west-2`) but this repo keeps everything on `us-west-2` for consistency
- Checked all 6 `bedrock-image-mcp-server` MCP configs (`accounting`, `ai-builder`, `frontend`, `image-gen`, `master`, `web-builder`) — all already set `AWS_REGION=us-west-2`, so no MCP server config change was needed, only prompt/doc guidance
- Left historical `CHANGELOG.md` entries describing past Nova Canvas additions unchanged (append-only history)
- Verified `./validate.sh` green


## Round 35 — 2026-07-28 -06:00

- Found the root cause of the user-reported "Tool ... is not available" errors: `steering/aws-agent-toolkit.md` and 8 other files instructed agents to hardcode literal AWS MCP tool names (`aws___search_documentation`, `aws___retrieve_skill`, etc.) as if they were guaranteed callable strings — directly contradicting `skills/mcp-tool-discovery.md`'s own rule to resolve names via `tool_search`, not hardcode them. The AWS MCP Server's tools resolve under different forms depending on the session (bare `aws___x` vs. fully-qualified `mcp_aws_mcp_server_aws___x`), so either hardcoded form fails intermittently
- Added a new "Resolving the correct tool name (MANDATORY)" section to `steering/aws-agent-toolkit.md`: on any "Tool is not available" error, resolve via `tool_search` first, try the other naming convention once if that also fails, verify the server is alive via a trivial call before concluding it's broken, never fabricate a workaround
- Live-verified the fix in this session: reproduced the exact failure (`aws___search_documentation` → not available), then confirmed `mcp_aws_mcp_server_aws___search_documentation` succeeds — this is a tested fix, not a guess
- Updated 9 files' hardcoded tool-name mentions to reference tools by short name + a pointer to the new resolution procedure: `prompts/reinvent.md`, `skills/deploy-on-aws.md`, `skills/cdk-infrastructure-patterns.md` (2 spots), `skills/aws-serverless-patterns.md`, `skills/mcp-tool-discovery.md`, `skills/openobserve-telemetry/SKILL.md`, `steering/aws-standards.md` (2 spots), `steering/mcp-server-preference.md`
- Left historical CHANGELOG.md/CHANGES.md/AWS-TOOLKIT-SKILLS-AUDIT.md mentions unchanged (append-only history)
- Verified `./validate.sh` green
