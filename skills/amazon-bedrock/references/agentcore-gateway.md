# AgentCore Gateway — Target Setup Procedure

## Gateway Concepts (read this first)

A **Gateway** is a single, secure entry point for an agent to reach tools, other agents, and models. Two configuration layers are easy to conflate — keep them separate:

1. **Inbound authorization** (who can call the Gateway) — set once, at the Gateway level:
   - **IAM (SigV4)** — AWS identity-based authorization
   - **OAuth (JWT)** — token-based authorization (e.g., Cognito, Okta, Entra ID)
   - **Authenticate only** — validates the token but delegates authorization to the target
   - **No authorization** — development/testing only, never production
2. **Outbound authorization** (how the Gateway authenticates to each _target's_ backend) — set per target, via `credentialProviderConfigurations`. Options depend on target type (see below); for AgentCore Runtime targets specifically: **IAM (SigV4)**, **Caller IAM credentials** (assumes a role on behalf of the caller), **OAuth (JWT)** (via an AgentCore Identity credential provider), or **Token passthrough** (validates and forwards the inbound token unmodified).

### Target categories

A single Gateway can have **multiple targets across three categories**, and a Gateway with MCP targets can mix multiple target _types_ within that category (e.g., one Lambda target + one MCP-server target + one Connector target, all aggregated):

| Category             | Behavior                                                                                                                                                                                                | Target types                                                                                                                                                                                                                          |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **MCP target**       | Aggregation mode — the Gateway merges all MCP targets into one unified virtual MCP server. Clients see a single consolidated `tools/list`. Supports semantic tool search and 3-legged OAuth per target. | Lambda functions, API Gateway REST APIs, OpenAPI specs, Smithy models, MCP servers, **Connectors** (Web Search Tool, Amazon Bedrock Managed Knowledge Bases), Integration provider templates (Console-only; see "Integrations" below) |
| **HTTP target**      | Direct passthrough — no aggregation, no protocol translation, no semantic search. Clients address each target individually via path-based routing (`/{targetName}/invocations`).                        | **AgentCore Runtime** agents (the "Agent target" in the console), other agents (A2A), external MCP servers, generic HTTP passthrough                                                                                                  |
| **Inference target** | Routes LLM traffic to one or more model providers through a unified endpoint, selecting the destination by the request's `model` field.                                                                 | Amazon Bedrock, OpenAI, Anthropic, and other model providers                                                                                                                                                                          |

### AgentCore Runtime targets ("Agent target") — the new, more secure way to expose a Runtime agent

Historically agents connected directly to an AgentCore Runtime endpoint. **Prefer fronting the Runtime with a Gateway instead** — the Gateway becomes the single governed entry point, giving you policy-based authorization, Bedrock Guardrails, request/response interceptors, and unified observability outside the agent's own environment, and lets you enforce that callers _cannot_ bypass the Gateway to hit the Runtime directly.

- **Target type**: select **AgentCore Runtime** as the target type, then point it at the Runtime's ARN (+ optional `qualifier`, defaults to `DEFAULT`).
- **Config shape**: `{"http": {"agentcoreRuntime": {"arn": "...", "qualifier": "DEFAULT", "schema": {"source": {"s3": {"uri": "..."}}}}}}`. `schema` is required to use Guardrails when the Runtime speaks plain HTTP; MCP/A2A Runtimes get a default schema automatically.
- **Outbound auth** (see above): IAM (SigV4), Caller IAM credentials, OAuth (JWT), or Token passthrough.
- **Enforcing gateway-only access**: configure this on the _Runtime_ side, not the Gateway — for IAM (SigV4) Runtimes, attach a resource-based policy restricting invocation to the Gateway's execution role; for OAuth (JWT) Runtimes, set `allowedWorkloadConfiguration` on the Runtime's `customJWTAuthorizer` to allow only the Gateway's workload.
- **Limitations vs. MCP targets**: no capability aggregation (each Runtime target is addressed individually via path-based routing), no semantic tool search, SSE streaming supported, interceptors only in buffered (non-streaming) mode. A Gateway target set to AgentCore Runtime cannot be added to an MCP-protocol-type Gateway.
- One Gateway can mix Agent targets and MCP targets — e.g., one Gateway fronting several Runtime agents plus a Connector for web search and one for a knowledge base.

### Choosing a target type: Connectors vs. Integrations vs. a custom MCP server

When an agent needs a new capability through the Gateway, work down this list — pick the first option that fits, don't reach for a custom build when a managed option covers it:

1. **Is it web search or your own enterprise data (RAG)?** → Use a **Connector** (Web Search Tool or Managed Knowledge Base). Zero infrastructure, zero credentials to manage, AWS operates and improves it for you. This is almost always the right answer for these two use cases specifically — don't build a custom MCP server for either.
2. **Is it a well-known third-party SaaS product** (Slack, Zoom, Asana, Jira, Microsoft, and others AWS adds over time)? → Check **Other Integrations** in the Console target-creation flow first. If a pre-built template exists for that provider, use it — it handles auth and schema for you. Integrations are Console-only (not available via the `create_gateway_target` API as of this writing), so if you need API-driven/IaC provisioning, this option is unavailable and you fall to option 3.
3. **Do you already have a REST API, Lambda function, or existing MCP server** that does what you need? → Expose it as a standard MCP target (OpenAPI spec, Lambda ARN, API Gateway, or MCP server) using the OpenAPI/Lambda/OAuth procedure below. This is the right choice when the capability is bespoke to your app/data and no Connector or Integration covers it.
4. **Are you exposing an AgentCore Runtime agent itself** (not a tool/data source)? → Use an **AgentCore Runtime target** ("Agent target"), not an MCP target — see "AgentCore Runtime targets" above.

Rule of thumb: Connector > Integration > custom MCP target > building the thing yourself outside the Gateway entirely. Each step down costs you more setup and more you have to maintain going forward.

### Built-in Connectors (new — prefer these over hand-rolled MCP servers)

Connectors are managed, pre-built MCP targets AWS operates for you — no infrastructure, credentials, or result-parsing to maintain. As of this writing there are two:

- **Web Search Tool** — see the "Web Search Tool Connector" section below. Use this instead of standing up a third-party search MCP server or API.
- **Amazon Bedrock Managed Knowledge Bases** — see the "Managed Knowledge Base Connector" section below. Use this instead of building a custom retrieval MCP server on top of Bedrock Knowledge Bases.

**Other Integrations** (Console-only, not via API) expose pre-configured templates for third-party providers (Slack, Zoom, Asana, Jira, Microsoft, and others) as targets — useful when an agent needs to act against a SaaS tool rather than retrieve data. Check the AgentCore console's target-creation flow for the current provider list, since it expands over time.

## Web Search Tool Connector

Fully managed, MCP-compatible web search — no search API to provision, no outbound credentials to manage, no result-parsing glue. Backed by a purpose-built AWS web index (tens of billions of documents, refreshed within minutes), with knowledge-graph grounding for factual queries and semantic snippet extraction tuned for model context. Queries stay inside AWS — they are never sent to a third-party search engine.

**When to use it**: any agent that needs current information outside your own data (news, prices, recent releases, "what happened today"). Complements, not replaces, knowledge bases — use a knowledge base for "what do our documents say" and Web Search for "what's true in the world right now." Many production agents use both.

**Setup** — attach it as an MCP target on an existing or new Gateway using `connectorId: "web-search"`:

```python
import boto3

gateway_client = boto3.client("bedrock-agentcore-control", region_name="us-east-1")

gateway_client.create_gateway_target(
    gatewayIdentifier=gateway_id,
    name="web-search-tool",
    targetConfiguration={
        "mcp": {
            "connector": {
                "source": {"connectorId": "web-search"},
                "configurations": [{"name": "WebSearch", "parameterValues": {}}],
            }
        }
    },
    credentialProviderConfigurations=[
        {"credentialProviderType": "GATEWAY_IAM_ROLE"}
    ],
)
```

**Outbound role/permissions** — the Gateway authenticates to the Web Search backend with its own IAM service role (`GATEWAY_IAM_ROLE`), not a search API key. Grant exactly two actions, scoped to the specific resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "InvokeGateway",
      "Effect": "Allow",
      "Action": "bedrock-agentcore:InvokeGateway",
      "Resource": "arn:aws:bedrock-agentcore:us-east-1:<ACCOUNT_ID>:gateway/<gateway-ID>"
    },
    {
      "Sid": "InvokeWebSearch",
      "Effect": "Allow",
      "Action": "bedrock-agentcore:InvokeWebSearch",
      "Resource": "arn:aws:bedrock-agentcore:us-east-1:aws:tool/web-search.v1"
    }
  ]
}
```

The role is for outbound auth only (Gateway → Web Search backend). It does NOT include `bedrock:InvokeModel` — model access stays with whatever identity runs the agent, not the Gateway service role. Inbound auth (who can call your Gateway) is configured separately at the Gateway level (IAM or JWT/OAuth — see "Gateway Concepts" above).

**Invocation** — any MCP-compatible framework (Strands, LangChain, LangGraph, CrewAI) discovers `WebSearchTool` via `tools/list` and calls it automatically when the agent needs current information. Results come back as an MCP `tools/call` text block containing serialized JSON: an `id` plus `results[]`, each with `title`, `url`, `publishedDate`, `text` (knowledge-graph facts have null `title`/`url` and structured key/value data in `text`).

**Region**: available today in `us-east-1` only — verify current regional availability before assuming it's available elsewhere.

**Pricing**: $7 per 1,000 queries.

## Managed Knowledge Base Connector

A native Gateway connector to **Amazon Bedrock Managed Knowledge Bases** — fully managed RAG (vector store, ingestion, retrieval optimization) with no retrieval infrastructure to provision. Prefer this over building a custom retrieval MCP server on top of Knowledge Bases. Supported only for Managed Knowledge Bases (not classic self-managed Bedrock Knowledge Bases), and only with IAM-based outbound auth (`GATEWAY_IAM_ROLE`).

**What it exposes** — two MCP tools per target, prefixed with the target name (e.g., `managed-kb___Retrieve`):

- **`Retrieve`** — a single hybrid search returning the most relevant passages with source references. The agent passes only `retrievalQuery.text`; the KB ID and retrieval settings are administrator-configured on the target (`managedSearchConfiguration`: `numberOfResults`, `overrideSearchType` (`HYBRID`/`SEMANTIC`), reranking, metadata `filter`). Expose specific fields to the agent via `parameterOverrides` if you want the agent able to override defaults per call.
- **`AgenticRetrieveStream`** — multi-step, streaming agentic retrieval: plans a retrieval strategy, runs multiple retrieval steps (optionally across several knowledge bases), and streams back a synthesized, citation-backed answer (`generatedResponse.answer` + `citations`) alongside the raw `results`. Set `generateResponse: false` to get results only. Good fit for multi-part or ambiguous questions that need multi-hop reasoning (e.g., "what's team X's budget, and does policy allow prepaying it" — two lookups plus a synthesis step). Progress streams over MCP as `notifications/message` (`traceEvent` for each planning/retrieval step, `responseEvent` for answer chunks).

**Access control**: the Gateway does NOT auto-populate row/document-level access control from the caller's IAM identity. If your KB filters by user/group, your application must explicitly pass `userContext` (e.g., `{"userId": "user@example.com"}`) in the `tools/call` arguments, and expose `$.userContext` via `parameterOverrides` on the target.

**Migration note**: Managed Knowledge Base uses the same APIs as classic Bedrock Knowledge Bases (`Retrieve`, `StartIngest`, `StopIngest`, `IngestKnowledgeBaseDocuments`) — pointing an existing integration at a new Managed KB ID requires no code changes.

**Native data connectors for ingestion** (separate from Gateway connectors — these feed the KB itself): Amazon S3, SharePoint, Confluence, Web Crawler, Google Drive, OneDrive. **Smart Parsing** auto-selects parsing strategy per source/content-type (no config needed). **Agentic Retriever** (the retrieval mode behind `AgenticRetrieveStream`) decomposes complex queries into a multi-step plan and executes multi-hop retrieval automatically.

**Regions** (at launch): US East (N. Virginia), US West (Oregon), Asia Pacific (Sydney, Tokyo), Europe (Dublin, Frankfurt, London), AWS GovCloud (US-West) — verify current availability before assuming a region is covered.

**Pricing**: based on indexed data size stored + number of retrievals performed (on-demand, no upfront commitment).

## OpenAPI / Lambda / OAuth Target Setup Procedure

The rest of this file covers the original, still-current procedure for exposing a REST API or Lambda function as an MCP target via OpenAPI schema, Lambda+IAM, or OAuth. Use the Connectors above instead when the target is web search or a Managed Knowledge Base — don't hand-roll those.

## Overview

Deterministic procedure for creating an AgentCore Gateway target that converts
REST APIs into MCP tools agents can use. Gateway supports three authentication
types, each with a different setup workflow. The creation order is strict —
credentials MUST be created before the gateway target.

## Parameters

- **auth_type** (required): `api_key` | `lambda_iam` | `oauth`
- **openapi_schema_s3_uri** (required): S3 URI of the OpenAPI schema
- **api_key** (required if api_key auth): The API key value
- **lambda_arn** (required if lambda_iam auth): Lambda function ARN
- **oauth_config** (required if oauth auth): Token endpoint, client ID, scopes

**Constraints for parameter acquisition:**

- You MUST ask for all required parameters (`auth_type`, `openapi_schema_s3_uri`, and auth-type-specific parameters) upfront in a single prompt
- You MUST confirm successful acquisition of all required parameters before proceeding to Step 1

## Steps

**General constraints:**

- You MUST present an overview of the steps before starting
- You MUST explain to the user what step is being executed and why before running each command
- You MUST respect the user's decision to abort at any point

### 0. Verify Dependencies

**Constraints:**

- You MUST verify the AWS CLI is available and configured before proceeding
- You MUST verify AWS CLI version ≥ 2.13.22 (required for AgentCore commands): `aws --version`
- You MUST inform the user about any missing tools and ask if they want to proceed

### 1. Upload OpenAPI Schema to S3

**Constraints:**

- You MUST upload the OpenAPI schema to S3 before creating the gateway target
- Schema MUST be valid OpenAPI 3.0 or 3.1
- You MUST include clear operation descriptions — Gateway uses these to generate MCP tool descriptions
- Upload the schema: `aws s3api put-object --bucket <bucket> --key <key> --body <schema-file>`
- Refer to the latest AWS documentation on AgentCore Gateway OpenAPI schema requirements

### 2. Create Credential Provider (if API key or OAuth)

**Constraints:**

- You MUST create the credential provider BEFORE creating the gateway target — this ordering is mandatory
- Creating a target without credentials results in a "credential provider not found" error

**For API key authentication:**

- You MUST NOT pass the API key as a literal value on the command line — shell history exposes it
- You MUST ask the user to set the key as an environment variable: `export API_KEY=<their-key>`
- Create the credential provider: `aws bedrock-agentcore-control create-api-key-credential-provider --name <name> --api-key "$API_KEY"` — the service encrypts and stores the key in Secrets Manager internally (response includes `apiKeySecretArn`). Do NOT manually create a Secrets Manager secret; the service manages this.
- For key rotation: `aws bedrock-agentcore-control update-api-key-credential-provider --name <name> --api-key "$NEW_API_KEY"` — do NOT call `secretsmanager rotate-secret` directly on the service-managed secret

**For OAuth authentication:**

- The client secret is passed via the `create-oauth2-credential-provider` API call — the service encrypts and stores it in Secrets Manager automatically (response includes `clientSecretArn`). Do NOT manually create a Secrets Manager secret.
- You MUST NOT hardcode client secrets in agent code or configuration
- Configure token endpoint, client ID, client secret, and scopes
- Create the OAuth2 credential provider: `aws bedrock-agentcore-control create-oauth2-credential-provider --name <name> --credential-provider-vendor <vendor> --oauth2-provider-config-input '...'`
- Refer to the latest AWS documentation on AgentCore Gateway OAuth configuration options

**For Lambda/IAM authentication:**

- No credential provider needed — skip to Step 3
- The Gateway uses IAM role-based authentication to invoke the Lambda
- The Lambda MUST have a resource-based policy allowing the Gateway service role to invoke it, with `aws:SourceAccount` and `aws:SourceArn` conditions to prevent confused deputy. Refer to the latest AWS documentation on AgentCore Gateway permissions for current policy patterns.

### 3. Create Gateway Target

**Constraints:**

- Create the target: `aws bedrock-agentcore-control create-gateway-target --gateway-identifier <gateway-id> --name <name> --target-configuration '...' --credential-provider-configurations '...'`
- You MUST link the OpenAPI schema S3 URI from Step 1
- If using API key or OAuth: You MUST link the credential provider ARN from Step 2
- If using Lambda: You MUST specify the Lambda ARN and configure IAM role with `lambda:InvokeFunction` scoped to the specific Lambda ARN — avoid `Resource: "*"`
- You MUST NOT create the target before the credential provider exists (for API key/OAuth)

### 4. Verify Target Status

**Constraints:**

- Poll target status: `aws bedrock-agentcore-control get-gateway-target --gateway-identifier <gateway-id> --target-id <target-id>`
- Wait for status `ACTIVE` before using the target
- If status is `FAILED`:
  - Check IAM permissions
  - Verify OpenAPI schema is valid
  - Verify credential provider exists and is accessible
  - Check CloudTrail for detailed error messages
- If status is stuck in `CREATING` for >10 minutes:
  - Contact AWS Support with the gateway-id and target-id for investigation
  - Refer to the latest AWS documentation or support channels for known issues

### 5. Test Connectivity

**Constraints:**

- You MUST test the gateway target with a sample request before using in production
- Verify the MCP tools generated from the OpenAPI schema match expectations
- You SHOULD report the list of generated MCP tools to the user

## Security Considerations

- **Encryption:** S3 encrypts objects at rest by default (SSE-S3). For sensitive schemas, use SSE-KMS with a customer managed key. Target endpoints MUST use HTTPS — Gateway rejects HTTP endpoints.
- **Least privilege:** Scope IAM roles to specific resource ARNs — the Gateway service role should only access the specific S3 bucket, Secrets Manager secret, and Lambda function needed. Avoid `Resource: "*"`.
- **Sensitive data in logs:** API keys and OAuth tokens may appear in CloudTrail logs. Enable CloudTrail log encryption with KMS. Do NOT log credential values in agent output.
- **Monitoring:** Enable CloudWatch alarms for gateway target errors (5xx rates, latency). Enable CloudTrail for audit logging of all `bedrock-agentcore-control` API calls.
- **TLS:** All target endpoints must use TLS 1.2+. Use ACM certificates for custom domains.
- Refer to the latest AWS documentation on Bedrock security best practices.
