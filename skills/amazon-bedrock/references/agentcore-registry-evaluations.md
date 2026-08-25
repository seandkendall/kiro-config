# AgentCore Registry & Evaluations

## Table of Contents

- AWS Agent Registry
- Evaluations Service

## AWS Agent Registry

Catalog, discover, and govern AI agents and tools across an organization.

> **Namespace migration (MANDATORY — read before using any Registry API):** AWS Agent Registry moved out of the `bedrock-agentcore` namespace into its own dedicated `agent-registry` namespace on **August 6, 2026**. The old `bedrock-agentcore`/`bedrock-agentcore-control` namespace for Registry shuts down on **September 17, 2026** — after that date the old CLI commands, ARNs, and IAM actions for Registry stop working entirely. Always use the new `agent-registry` namespace for any new work; if you find a project still using the old namespace, treat it as needing migration, not as a valid current pattern. **This migration affects Registry only** — Identity, Gateway, Runtime, and Policy stay under `bedrock-agentcore` unchanged. Do not "helpfully" rename those.

### What changed (new namespace, new schema)

- **CLI/SDK**: `aws bedrock-agentcore-control` → `aws agent-registry-control` (control plane), `aws bedrock-agentcore` → `aws agent-registry` (data plane). SDK client classes: `BedrockAgentCoreClient`/`BedrockAgentCoreControlClient` → `AgentRegistryClient`/`AgentRegistryControlClient`.
- **Endpoints**: `bedrock-agentcore-control.{region}.amazonaws.com` → `agent-registry-control.{region}.api.aws` (note the new `.api.aws` domain, not `.amazonaws.com`).
- **IAM**: action prefix `bedrock-agentcore:*` → `agent-registry:*`; service principal `bedrock-agentcore.amazonaws.com` → `agent-registry.amazonaws.com`. **Exception**: if a registry record uses `source.fromUrl` with OAuth or IAM sync credentials, keep `bedrock-agentcore:CreateWorkloadIdentity` / `GetWorkloadIdentity` / `DeleteWorkloadIdentity` alongside the new `agent-registry:*` permissions — workload identity stays on the old namespace intentionally.
- **Managed policy**: `BedrockAgentCoreFullAccess` does NOT get `agent-registry:*` added to it. Use the new `AgentRegistryFullAccess` managed policy instead.
- **ARNs**: `arn:aws:bedrock-agentcore:{region}:{account}:registry/{id}` → `arn:aws:agent-registry:{region}:{account}:registry/{id}` (and `.../record/{rid}` for records).
- **Observability**: CloudTrail event source `bedrock-agentcore.amazonaws.com` → `agent-registry.amazonaws.com`; EventBridge source `aws.bedrock-agentcore` → `aws.agent-registry`; CloudWatch namespace `AWS/BedrockAgentCore` → `AWS/AgentRegistry`. Update any EventBridge rules, CloudTrail Lake / Athena queries, and CloudWatch dashboards/alarms that reference the old values. **Also update any EventBridge rule matching the old registry-lifecycle detail-type string** — it changed from a full sentence (`"Registry State transitions from Creating to Ready"`) to a short status string (`"Registry Ready"`); a rule matching the old sentence silently stops firing after migration, it doesn't error.
- **API schema** — several breaking model changes, not just a rename:
  - Registry-level `authorizerType`/`authorizerConfiguration` moved under a new `discoveryConfiguration` wrapper.
  - `approvalConfiguration.autoApproval` (boolean) → `approvalConfiguration.autoApprovalRules` (array of enum strings; `["APPROVE_ALL"]` is the equivalent of the old `autoApproval: true`, empty array `[]` means manual approval).
  - Records gain two new **required** top-level fields: `name` (unique dedup key within the registry) and `recordType` (enum: `AGENT` | `MCP` | `SKILL` | `CUSTOM`, replaces the old `descriptorType`).
  - The old `name` field is renamed `displayName`. `descriptors` is now a flat keyed structure (`a2aAgentCard`, `mcpServer`, `agentSkillsDefinition`, `custom` as top-level keys) instead of a discriminated union keyed by `descriptorType`. `inlineContent` → `data`; `schemaVersion`/`protocolVersion` → unified `dataSchemaVersion`; the old top-level `synchronizationConfiguration` moves to a per-descriptor `source` field (only `mcpServer` and `a2aAgentCard` carry `source`; only `source.fromUrl` is supported).
  - Record status lifecycle is now `DRAFT` → `PENDING_APPROVAL` → `APPROVED` | `REJECTED` | `DEPRECATED` — **not** the old `PENDING` → `APPROVED` → `ACTIVE`/`REJECTED` model this file described before this update. If you see `PENDING`/`ACTIVE` referenced anywhere else, that's the pre-migration status model and is stale.
  - `SearchRegistryRecords` → `SearchDiscoverableRegistryRecords`; the MCP tool `search_registry_records` → `search_discoverable_registry_records`. Filter field names changed (`recordType` replaces `descriptorType`, `recordVersion` replaces `version`).
  - List APIs (`ListRegistries`, `ListRegistryRecords`) moved from `GET` with discrete query params to `POST` with a structured `filters: [{"name": "<dotted.path>", "values": [...]}]` body.
  - New browsing APIs with no migration needed, additive only: `ListDiscoverableRegistryRecords` (paginated browse over approved records) and `BatchGetDiscoverableRegistryRecord` (batch detail fetch across records in one registry, 1-100 record IDs per call).

### Governance Workflow

Two approval modes, same concept as before, new field name:

| Mode                | Behavior                                                                                             | Use For                                           |
| ------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| **Auto-approve**    | `approvalConfiguration.autoApprovalRules: ["APPROVE_ALL"]` — records become discoverable immediately | Development environments (isolated accounts only) |
| **Manual approval** | `approvalConfiguration.autoApprovalRules: []` — records require explicit approval before discovery   | Production environments                           |

Status transitions (current, post-migration model): `DRAFT` → `PENDING_APPROVAL` → `APPROVED` (or `REJECTED`, or later `DEPRECATED`).

**Common failure**: Record stuck in `PENDING_APPROVAL` — governance workflow is set to manual approval but no one has approved. Check `approvalConfiguration` or switch to `autoApprovalRules: ["APPROVE_ALL"]` for dev.

**Sync-specific failure (new namespace only)**: if a record uses `source.fromUrl` with an IAM role credential, its sync fails with the role's trust policy still pointing at `bedrock-agentcore.amazonaws.com` after migrating from the old namespace — the assuming principal is now `agent-registry.amazonaws.com`. If it already failed, the record sits in `CREATE_FAILED`; you cannot just fix the trust policy and retry — delete the `CREATE_FAILED` record and recreate it after fixing the trust policy.

### Registering Resources

Resource types: MCP servers (`mcpServer` descriptor), A2A agents (`a2aAgentCard` descriptor), agent skills (`agentSkillsDefinition` descriptor), custom types (`custom` descriptor). Exactly one primary descriptor per record, valid per `recordType`: `AGENT` → `a2aAgentCard`/`mcpServer`/`custom`; `MCP` → `mcpServer`/`custom`; `SKILL` → `agentSkillsDefinition`/`custom`; `CUSTOM` → `custom` only.

**Constraints:**

- You MUST specify `name` (unique dedup key), `recordType`, `displayName`, and a description
- You MUST register via the current namespace: `aws agent-registry-control create-registry-record --registry-id <registry-id> --name <name> --record-type <AGENT|MCP|SKILL|CUSTOM> --description "<desc>" --endpoint-url https://agent-registry-control.<region>.api.aws`
- Tags and capabilities metadata improve discoverability
- Auto-synchronization only runs for `mcpServer` and `a2aAgentCard` primary descriptors (i.e., `MCP` and `AGENT` record types). `SKILL` records cannot auto-sync — a `source` on the `skillMd` child is persisted but not acted on. `CUSTOM` records must be created with `data` provided directly, never via sync.

### Searching and Discovery

- CLI: `aws agent-registry-control list-registry-records --registry-id <registry-id> --endpoint-url https://agent-registry-control.<region>.api.aws` — takes a structured `filters` body, not discrete query flags, in the current namespace
- Broad search across approved records: `SearchDiscoverableRegistryRecords` (filter by `recordType`, `recordVersion`)
- Browse approved records without a search query: `ListDiscoverableRegistryRecords`
- Batch-fetch full record details across a registry: `BatchGetDiscoverableRegistryRecord` (needs IAM permission for `agent-registry:GetDiscoverableRegistryRecord` — it has no dedicated action of its own, it authorizes each requested record against that action)
- MCP endpoint: programmatic discovery via MCP protocol, tool name `search_discoverable_registry_records`
- Filter by resource type (`recordType`), tags, capabilities

### Migrating an existing registry off the old namespace

If a project has existing registries/records under `bedrock-agentcore`, they must be moved before **September 17, 2026** (the old namespace shuts down entirely on that date). AWS provides a migration tool in the `agentcore-samples` GitHub repository — do not hand-roll a migration script. Three approaches, by scale:

1. **Simple** — a one-time full migration is enough (no unattended/incremental need): run the tool directly from a terminal or CloudShell, no infrastructure to deploy.
2. **Managed (AWS Glue)** — need unattended execution or an incremental load at cutover: deploy the provided CDK stack as Glue jobs; run a full migration, operate both namespaces in parallel while validating, then run an incremental load at cutover.
3. **Active-active** — actively writing to the old namespace in production via automation: full migration first, then write to both namespaces simultaneously during validation, then cut over reads/writes and decommission the old integration.

After migrating: update IAM policies/endpoints/SDK clients per "What changed" above, fix trust policies on any sync IAM roles (see Governance Workflow above), and verify record/registry counts match between namespaces before decommissioning the old one.

### Available Regions

Verify availability in the new namespace: `aws agent-registry-control list-registry-records --registry-id <registry-id> --region <region> --endpoint-url https://agent-registry-control.<region>.api.aws`.

## Evaluations Service

Automated agent quality assessment using LLM-as-a-Judge. **Not affected by the Registry namespace migration above** — Evaluations stays under `bedrock-agentcore`.

### Setup Workflow

```
Evaluation Setup:
- [ ] Step 1: Instrument agent with OTEL (see [memory & observability](agentcore-memory-observability.md))
- [ ] Step 2: Create evaluators (built-in or custom)
- [ ] Step 3: Configure online evaluation (sampling rate, data source)
- [ ] Step 4: Monitor scores in CloudWatch
```

### Built-in Evaluators

| Evaluator              | What It Measures                              |
| ---------------------- | --------------------------------------------- |
| `Builtin.Helpfulness`  | Does the response help the user?              |
| `Builtin.Faithfulness` | Is the response grounded in provided context? |
| `Builtin.Harmfulness`  | Does the response contain harmful content?    |

Refer to the latest AWS documentation on AgentCore Evaluations built-in evaluators for the full current list.

### Custom Evaluators

Define your own evaluation criteria:

- Rubric: what constitutes a good/bad response for your use case
- Scoring scale: numeric (1-5) or binary (pass/fail)
- Custom prompt template: the LLM-as-a-Judge prompt

Create custom evaluators: `aws bedrock-agentcore-control create-evaluator --evaluator-name <name> --level <TOOL_CALL|TRACE|SESSION> --evaluator-config '{"llmAsAJudge":{"instructions":"<criteria>","ratingScale":{"numerical":[{"value":1,"description":"Poor"},{"value":5,"description":"Excellent"}]}}}'`

### Online vs On-Demand Evaluation

| Type          | When                                   | Use For                            |
| ------------- | -------------------------------------- | ---------------------------------- |
| **Online**    | Continuous, samples production traffic | Monitoring quality over time       |
| **On-demand** | Batch, against a test dataset          | Regression testing, A/B comparison |

**Online evaluation constraints:**

- Configure sampling rate — evaluating every invocation is expensive (each evaluation is a model invocation)
- Start with 5-10% sampling, increase if quality issues detected
- Data source: which OTEL traces to evaluate

### Monitoring Scores

- Evaluation scores publish to CloudWatch automatically
- Create alarms for quality degradation: score drops below threshold
- Investigate low-scoring sessions: trace → evaluation result → root cause
- Create quality alarms — first discover the exact namespace (CloudWatch namespaces are case-sensitive):
  1. `aws cloudwatch list-metrics --namespace "Bedrock-AgentCore"` — if no results, try `--namespace "Bedrock-Agentcore"`
  2. Use the namespace that returns metrics in subsequent commands:

  `aws cloudwatch put-metric-alarm --alarm-name <name> --metric-name <metric> --namespace "<discovered-namespace>" --statistic Average --period 300 --threshold <value> --comparison-operator LessThanThreshold --evaluation-periods 3 --alarm-actions "<sns-topic-arn>"`

## Security Considerations

**Registry access control (current `agent-registry` namespace):**

- You MUST use least-privilege IAM policies — separate read (`agent-registry:ListRegistryRecords`, `agent-registry:GetRegistryRecord`) from write (`agent-registry:CreateRegistryRecord`, `agent-registry:UpdateRegistryRecord`) permissions. Avoid `agent-registry:*`
- You MUST use IAM roles (not IAM users) for programmatic registry access
- You SHOULD add `aws:SourceArn` and `aws:SourceAccount` conditions to resource policies on registry resources
- You MUST restrict auto-approve governance mode (`autoApprovalRules: ["APPROVE_ALL"]`) to isolated development accounts — use manual approval (`autoApprovalRules: []`) in shared or production environments
- If any record syncs via `source.fromUrl` with an IAM role, that role's trust policy must trust `agent-registry.amazonaws.com` (not the old `bedrock-agentcore.amazonaws.com` principal) — see the Governance Workflow section above for the migration-specific failure mode

**Evaluation data protection:**

- OTEL traces sent to evaluations contain user queries, agent responses, and tool call parameters — these may include PII
- You MUST ensure OTEL trace data is encrypted in transit (TLS) and at rest
- You SHOULD implement PII scrubbing in OTEL instrumentation before traces reach the evaluation service
- You MUST restrict access to evaluation results to authorized personnel only
- Encrypt CloudWatch log groups storing evaluation results with KMS

**Monitoring security:**

- You MUST encrypt SNS topics used for alarm actions with KMS
- You MUST validate that SNS topic subscribers are authorized to receive evaluation data
- You MUST enable CloudTrail for all `agent-registry-control` API calls (Registry) and `bedrock-agentcore-control` API calls (Evaluations, and Registry activity still on the old namespace during a migration window) — tracks who registered resources, who approved/rejected records, and who modified evaluations

- Refer to the latest AWS documentation on Bedrock AgentCore security best practices.
