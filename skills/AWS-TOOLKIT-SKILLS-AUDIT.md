# AWS Agent Toolkit Skills Audit

Date: 2026-06-23

## Why this audit exists

The **AWS MCP Server (Agent Toolkit for AWS)** went GA in May 2026. Our `aws-mcp-server`
already points at the managed endpoint (`mcp-proxy-for-aws@latest →
https://aws-mcp.us-east-1.api.aws/mcp`). That managed server now exposes:

- `aws___retrieve_skill` — pulls curated AWS skills **on demand**
- **Agent SOPs** — pre-built best-practice workflows
- `aws___search_documentation` — authoritative docs (consolidates AWS Knowledge MCP + AWS API MCP)

Several skills bundled in this repo are **local copies of the same awslabs skills** the managed
server can now retrieve on demand. This audit MARKS the overlap. **It does not delete anything** —
trimming is destructive and requires explicit owner sign-off (see "Decision" below).

## New Agent Toolkit core skills (retrieve on demand — do not vendor)

- **`aws-auth`** (added Aug 2026) — Amazon Cognito user pool/identity pool setup, managed login/OAuth flows, tokens, JWT authorizers, passkey/WebAuthn, threat protection, Lambda triggers. Retrieve via `aws___retrieve_skill` when doing Cognito work — do NOT vendor a local copy (same on-demand pattern as the retired skills below). **Its default guidance recommends the Cognito hosted UI — this repo's `aws-standards.md` "Custom Login UI (MANDATORY)" rule overrides that; never follow the skill's hosted-UI steer.** See the cross-reference in `steering/aws-standards.md`.

## AgentCore Gateway Connectors — checked, no Agent Toolkit overlap (Aug 2026)

`aws___search_documentation` (topic `agent_skills`) was queried for AgentCore/Gateway/Bedrock coverage while writing `skills/amazon-bedrock/references/agentcore-gateway.md`'s Connectors guidance (Web Search Tool, Managed Knowledge Bases). No matching skill exists in the managed registry — this is Bedrock/AgentCore **product** documentation, not an Agent Toolkit **skill**, so there's nothing to retrieve on demand here and no vendoring decision to make. Keep maintaining this guidance directly in the `amazon-bedrock` skill (already the "keep" exception above) rather than expecting the managed server to serve it.

## Bundled awslabs skills (trim candidates)

These 15 directories were vendored from `awslabs/mcp` (each has a `SKILL.md`, dated 2026-05-06).
The managed server can serve equivalents via `aws___retrieve_skill` / Agent SOPs:

| Skill dir                                     | Trim candidate?    | Note                                                                                                                                                                    |
| --------------------------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `amazon-bedrock`                              | **Keep (for now)** | We extended it (AgentCore harness GA note); also referenced directly by `ai-builder` as a `skill://` resource. Re-vendor from upstream only if we drop the local edits. |
| `aws-serverless`                              | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `aws-observability`                           | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `aws-iam`                                     | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `aws-cloudformation`                          | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `aws-billing-and-cost-management`             | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `aws-messaging-and-streaming`                 | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `securing-s3-buckets`                         | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `creating-secrets-using-best-practices`       | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `setting-up-cloudwatch-alarm-notifications`   | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `troubleshooting-application-failures`        | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `debugging-lambda-timeouts`                   | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `connecting-lambda-to-api-gateway`            | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `connecting-lambda-to-dynamodb`               | Trim candidate     | Retrievable on demand                                                                                                                                                   |
| `routing-traffic-with-route53-and-cloudfront` | Trim candidate     | Retrievable on demand                                                                                                                                                   |

## Custom skills (KEEP — unique to this repo, not in the managed server)

`cdk-infrastructure-patterns`, `react-frontend-patterns`, `aws-serverless-patterns`,
`testing-patterns`, `deploy-on-aws`, `deploy.sh.template`, `gitignore.template`,
`aws-architecture-diagram`, `aws-diagram-png`, `mcp-tool-discovery`,
`email-template-rendering` + `email-templates/`, `cognito-email-migration`,
`cypress-to-playwright-migration` (+ playwright templates), `personal-rules-management`.

These encode this repo's opinions (CDK-Python-only, deploy.sh contract, Playwright-only E2E,
custom email standards, personal-rules protocol) and have **no managed-server equivalent**. Keep all.

## Trade-off (why this is "mark," not auto-"trim")

Retiring the 15 vendored awslabs skills would:

- **Pro:** less to maintain/re-vendor; the managed server stays current automatically.
- **Con:** loses offline/`/skill-name` slash-command access and progressive frontmatter loading;
  each use becomes an on-demand `aws___retrieve_skill` round-trip; exact skill names/coverage on
  the managed server should be confirmed before deleting local copies.

## Decision

> **EXECUTED 2026-07-21** — owner approved; the 14 trim-candidate directories were deleted.
> `amazon-bedrock` retained (locally extended). Retrieve equivalents on demand via
> `aws___retrieve_skill` / `aws___search_documentation` (topic filter `agent_skills`).

- **Now:** MARK only (this document). Keep `amazon-bedrock` regardless (locally extended + referenced by `ai-builder`).
- **Before trimming:** confirm each trim-candidate has a managed-server equivalent via
  `aws___search_documentation` (topic filter `agent_skills`) / `aws___retrieve_skill`, then remove the
  vendored copies in a single reviewed change. Deletion is destructive — owner sign-off required.
