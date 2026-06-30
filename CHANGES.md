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
