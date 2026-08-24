---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
name: aws-standards
description: 'AWS development standards: CDK Python (never TypeScript), resource tagging, cdk-nag, AWS Resource Groups (tag-based), Lambda Powertools, Cognito custom UI + passkeys, S3 OAC, Lambda resilience (DLQ + idempotency), API routing through CloudFront /api path. Use when writing or reviewing CDK, Lambda, or AWS infrastructure code.'
---

# AWS Development Standards

> When uncertain about an AWS service, API, IAM action, or limit, use `aws___search_documentation` and `aws___retrieve_skill` from the `aws-mcp-server` MCP server. If unsure which MCP tool covers your task, see `skills/mcp-tool-discovery.md` for the discovery flow.

## CDK Infrastructure

**Language Requirement** - ALL CDK code MUST be written in Python. No TypeScript CDK. Lambda functions in Python.

**CDK Alpha Modules (MANDATORY)** - Before using any `*_alpha` CDK module, check whether it has graduated to stable in `aws-cdk-lib`. Alpha modules are separate `pip` packages (`aws-cdk.aws-<service>-alpha`) with no backward-compatibility guarantee; most eventually graduate into `aws-cdk-lib` and the alpha package is then deprecated.

- **Always prefer the stable module** when one exists. Stable constructs live in `aws-cdk-lib` and import as `from aws_cdk import aws_<service>`.
- **Verify before using an alpha** — use `aws___search_documentation` (AWS MCP server) or check the module's PyPI page. If the PyPI page says "deprecated / moved to aws-cdk-lib" or the Development Status is "Inactive", the alpha is dead; use the stable path.
- **Known graduations** (use the stable path, NOT the alpha):
  - `aws-cdk.aws-apigatewayv2-alpha` → **deprecated Dec 2023**. Use `aws_cdk.aws_apigatewayv2` (HTTP/WebSocket API: `HttpApi`, `CorsPreflightOptions`, `HttpMethod`, `DomainName`), `aws_cdk.aws_apigatewayv2_integrations` (`HttpLambdaIntegration`, `HttpUrlIntegration`, etc.), and `aws_cdk.aws_apigatewayv2_authorizers` (`HttpJwtAuthorizer`, etc.). All three are now in `aws-cdk-lib` — no separate `pip install` needed.
- **Still alpha** (verified at CDK **2.260.0** on 2026-06-23 — publishes as `2.260.0a0`, Development Status: Beta; re-check before relying on it): `aws_lambda_python_alpha` (`PythonFunction`). It has NOT graduated — the alpha package is still required. (We no longer use `aws_servicecatalogappregistry_alpha` / `ApplicationAssociator`: AWS Service Catalog AppRegistry moved to maintenance on 2026-06-30 — use the stable `aws_resourcegroups.CfnGroup` instead; see "AWS Resource Groups" below.)

**Construct Level (MANDATORY) — prefer L2/L3 over L1** - Always use the highest-level construct available. Prefer **L3** (patterns) and **L2** (curated resources with sensible defaults) over **L1** (`Cfn*`, raw CloudFormation 1:1).

- Whenever guidance, a snippet, or generated code reaches for an **L1 `Cfn<Resource>`** construct, first **verify whether the current `aws-cdk-lib` now ships an L2/L3** for that resource — use `aws___search_documentation` (AWS MCP server) or the construct's PyPI/API-reference page — and **propose the higher-level construct instead**.
- Only fall back to an L1 `Cfn*` when **no L2/L3 exists** (or the L2 genuinely can't express what you need). When you do, leave a short comment saying so and noting it should be revisited.
- **Re-check on every CDK upgrade.** L2s graduate continuously; an L1 you used last quarter may have an L2 now. The daily-maintenance dependency upgrade (`development-workflow.md`) is the natural point to re-evaluate.
- Current known L1-only exception in this config: **`aws_resourcegroups.CfnGroup`** — `aws-cdk-lib` has **no L2** for Resource Groups as of CDK 2.260 (verified 2026-06-23), so L1 is correct here for now; re-check on upgrade.

**Resource Tagging** - Tag ALL resources in every stack (mandatory):

```python
from aws_cdk import Tags
Tags.of(stack).add('auto-stop', 'false')
Tags.of(stack).add('auto-delete', 'false')
Tags.of(stack).add('project', project_name)
```

**Stack Naming** - NEVER use default CDK stack names (`CdkStack`, `CdkBackendStack`, `Stack`). Every stack MUST have a unique, project-specific name that clearly identifies the application and environment (e.g., `InvoiceAppDevStack`, `InvoiceAppProdStack`).

**Security Validation** - Always include cdk-nag:

```python
from cdk_nag import AwsSolutionsChecks
from aws_cdk import Aspects
Aspects.of(app).add(AwsSolutionsChecks())
```

**AWS Resource Groups (MANDATORY)** - Every CDK app MUST register its resources in a **tag-based AWS Resource Group** for governance, cost tracking, and operational visibility — a single Console/CLI/SDK view of everything the app owns.

> **Why not Service Catalog AppRegistry / myApplications?** Per the AWS announcement on 2026-06-30, **AWS Service Catalog – Application Registry** and the **myApplications** console experience moved to **maintenance** (effective 2026-07-30: no new applications or updates; existing ones stay viewable). AWS recommends **AWS Resource Groups** (tag-based) as the replacement. Do NOT use `ApplicationAssociator` / `aws_servicecatalogappregistry_alpha` in new code — see the migration procedure below for existing projects.

Resource Groups uses the **stable** `aws_cdk.aws_resourcegroups.CfnGroup` (`AWS::ResourceGroups::Group`) — no alpha package required. Build the group from the mandatory `project` tag every stack already applies.

Register in `app.py` (or your top-level stack):

```python
import os
import aws_cdk as cdk
from aws_cdk import Stack, Tags, aws_resourcegroups as resourcegroups
from constructs import Construct

app = cdk.App()
region = os.environ.get('CDK_DEFAULT_REGION', 'us-east-1')
project_name = 'MyApp'


class MyAppStack(Stack):
    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # ... define your resources here ...

        # Tag-based Resource Group: every resource tagged project=<name> joins it.
        resourcegroups.CfnGroup(self, 'AppResourceGroup',
            name=f'{project_name}-{region}',
            description=f'{project_name} resources in {region}',
            resource_query=resourcegroups.CfnGroup.ResourceQueryProperty(
                type='TAG_FILTERS_1_0',
                query=resourcegroups.CfnGroup.QueryProperty(
                    resource_type_filters=['AWS::AllSupported'],
                    tag_filters=[
                        resourcegroups.CfnGroup.TagFilterProperty(
                            key='project', values=[project_name],
                        ),
                    ],
                ),
            ),
        )


stack = MyAppStack(app, f'{project_name}Stack-{region}')

# Tag every stack so its resources land in the group (see Resource Tagging above).
Tags.of(stack).add('project', project_name)

app.synth()
```

Rules:

- The group is **tag-based on `project=<name>`** — keep applying the mandatory `project` tag to every stack (see Resource Tagging). No `awsApplication` tag, no AppRegistry application.
- `name` should be unique per account per region (e.g., `{project}-{region}`).
- `resource_type_filters=['AWS::AllSupported']` includes every taggable resource type; narrow it only if you want a subset.
- Resource Groups are Region-scoped — create one per region you deploy to.
- Do NOT rely on **Resource Groups – Group Lifecycle Events** (also moved to maintenance on 2026-06-30); plain tag-based groups are fully supported.

#### Migrating an existing project off myApplications / AppRegistry (NON-DESTRUCTIVE)

If a project still uses `ApplicationAssociator` / AppRegistry (the `awsApplication` tag + myApplications), migrate it to a tag-based Resource Group. **This migration MUST be non-destructive** — it changes only the _grouping_ mechanism. Workload resources (Lambda functions, CloudWatch log groups, S3 buckets, DynamoDB/RDS/Aurora databases, SQS queues, etc.) MUST NOT be deleted.

Why it's safe: deleting the **AppRegistry Application** removes only the Service Catalog registry entry and its resource _associations_ — it does NOT delete the associated workload resources. Removing the `awsApplication` tag is metadata-only. Neither touches your data or compute.

Procedure:

1. **Add the Resource Group** — add the `CfnGroup` above (tag-based on `project=<name>`) and ensure every stack applies the `project` tag. Deploy. Confirm the new group lists the expected resources (`aws resource-groups list-group-resources --group-name <name>`, via `aws-mcp-server`).
2. **Remove the AppRegistry wiring** — delete the `ApplicationAssociator` block (and the `aws-cdk.aws-servicecatalogappregistry-alpha` dependency) from `app.py`. On the next `deploy.sh`, CloudFormation deletes only the AppRegistry **Application** (and the separate `*-AppRegistry-*` application stack, if one was created) — NOT the workload stacks.
3. **Drop the `awsApplication` tag only if nothing else uses it.** It is optional: AWS keeps the tag working for grouping, so you may leave it in place. If you remove it, do so via tag changes only — never by recreating resources.
4. **Never `cdk destroy`, never empty/delete S3 buckets, never delete log groups, queues, or databases as part of this migration.** If `deploy.sh --delete` exists, do NOT run it — migration is a deploy, not a teardown.
5. **Verify post-migration:** workload resources still exist and function, the Resource Group shows them, and the old AppRegistry application is gone (or intentionally left). Run live tests against deployed endpoints.

> Guardrail: if an agent is ever unsure whether a migration step would delete a workload resource, STOP and ask the user. The only things this migration may remove are the AppRegistry Application and the (now-unused) `awsApplication` tag.

**Lambda Functions** - Use `PythonFunction` construct with Python 3.14:

```python
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime

PythonFunction(self, 'MyFunction',
    runtime=Runtime.PYTHON_3_14,
    entry='cdk-backend/lambda/functions/my_function',
    index='my_function.py'
)
```

**DynamoDB Tables** - GSI creation/deletion limits:

- Only add/remove ONE GSI per `cdk deploy`
- Wait for deployment completion before next GSI change

**DynamoDB Encryption (MANDATORY — ALWAYS DEFAULT, NEVER CHANGE)** - Every DynamoDB table MUST use DynamoDB's default encryption (AWS owned key). This is non-negotiable:

- **Do NOT set `encryption=` on `dynamodb.Table` / `dynamodb.TableV2` at all.** Simply omit the parameter — CDK's default is `TableEncryption.AWS_OWNED`, which is exactly what we want.
- **NEVER set `encryption=dynamodb.TableEncryption.AWS_MANAGED`** (customer's AWS-managed KMS key) or `CUSTOMER_MANAGED` (customer-managed KMS key) on any DynamoDB table, in any project, for any reason. This applies even if a project seems to call for "encryption at rest" — DynamoDB's default already provides encryption at rest; switching modes only adds KMS cost, complexity, and IAM/key-policy surface area with no security benefit for our workloads.
- This is a deliberate **exception** to the general "encrypt everything with KMS" security rule (`security-policies.md`) — DynamoDB is excluded from that rule by design. S3, SQS, SNS, and EBS still use KMS; DynamoDB does not.
- If a CDK diff or code review shows `encryption=` being added to a DynamoDB table construct, treat it as a regression — remove the parameter, don't change its value.
- Applies identically to CloudFormation (`AWS::DynamoDB::Table` — omit `SSESpecification`, or if present, do not set `SSEType`/`KMSMasterKeyId`) and any other IaC tooling.

**S3 Buckets** - Let CDK auto-generate names, avoid `bucket_name` parameter

## Serverless Development

**AWS Lambda Powertools** - Always use for structured logging, tracing, and metrics:

```python
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext

logger = Logger()
tracer = Tracer()
metrics = Metrics()

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def lambda_handler(event: dict, context: LambdaContext) -> dict:
    logger.info("Processing request", extra={"request_id": context.request_id})
    metrics.add_metric(name="RequestProcessed", unit="Count", value=1)
    return {"statusCode": 200}
```

**X-Ray Tracing** - Enable active tracing on ALL:

- Lambda functions: `tracing=lambda_.Tracing.ACTIVE` in CDK
- API Gateway stages: `tracing_enabled=True`
- Step Functions state machines: `tracing_enabled=True`
- Use Powertools Tracer `@tracer.capture_method` for custom subsegments

## Authentication

**Cognito Configuration** - Use newer managed login version:

```python
managed_login_version=cognito.ManagedLoginVersion.NEWER_MANAGED_LOGIN
```

**Custom Login UI (MANDATORY)** - NEVER use the Cognito Hosted UI. Always build custom pages:

- Custom **login page** — username/password MUST always be supported as the baseline sign-in method; passkey is an additional, optional method offered alongside it (see "Passkeys" below)
- Custom **registration page** with email verification; when the user sets a password, ALWAYS require both a **password** field and a **confirm password** field (client-side match check before submit, in addition to server-side validation)
- Custom **password reset page** (forgot password flow) — the "Forgot password?" / reset-password flow MUST be enabled and reachable from the login page in every app; this is not optional
- Use the Cognito Identity SDK or `amazon-cognito-identity-js` / `@aws-amplify/auth` for all auth flows

> **Agent Toolkit `aws-auth` skill (Cognito, added Aug 2026)** — the AWS-managed `aws-auth` core skill in the Agent Toolkit for AWS (retrieve via `aws___retrieve_skill` per `aws-agent-toolkit.md`) is a good reference for user pool vs. identity pool selection, the `update-user-pool-client` / `set-identity-pool-roles` full-replace read-modify-write trap, PKCE vs. implicit grant, token storage/rotation, JWT authorizer wiring, passkey/WebAuthn enrollment, and threat protection. **Its default recommendation is the Cognito hosted UI / managed login — that conflicts with our Custom Login UI mandate above. Our rule wins: never follow the skill's hosted-UI guidance, always build custom pages.** Use the skill for the underlying Cognito mechanics (tokens, triggers, identity pools, authorizers), not for UI delivery.

**Custom Cognito Emails (MANDATORY)** - NEVER use the default Cognito verification, password-reset, or MFA emails. Wire up the `CustomEmailSender` Lambda trigger and send brand-matched HTML via SES. Full rule: `email-standards.md`.

**Passkeys (MANDATORY)** - ALWAYS enable WebAuthn/passkeys as an optional login method — password remains the required baseline (see "Custom Login UI" above), passkey is an add-on, never a replacement:

- Passkeys MUST be available on the login page as an additional sign-in option, alongside username/password — NOT positioned as the primary or first-shown method, and NOT required for any user to sign in
- After login, users MUST be able to add multiple passkeys from their account settings (any number of devices)
- Use Cognito's WebAuthn support with `USER_AUTH` flow and `WEB_AUTHN` challenge
- Passkey registration: allow users to name each passkey (e.g., "MacBook Pro", "iPhone 15")
- Passkey management: list, rename, and delete registered passkeys from account settings

**Post-Login Passkey Nudge Modal (MANDATORY)** - For any authenticated user who has NOT yet registered a passkey, show a modal after login encouraging them to add one:

- Trigger: fires once per qualifying login, only when the signed-in user has zero registered passkeys
- Content: brief explanation of the benefit (faster, phishing-resistant sign-in) + a primary CTA to start passkey registration + a secondary "Maybe later" dismiss action
- MUST include a **"Don't show this again"** checkbox — when checked and dismissed, persist that preference (per-user, e.g., a `user_preferences` attribute or DynamoDB record) so the modal never reappears for that user, even after future logins
- Without the checkbox checked, a plain dismiss ("Maybe later") is allowed to re-show the modal on a subsequent login (don't nag every single login by default — a reasonable cadence, e.g., once per session or once per N days, is acceptable; never block the app behind this modal)
- Use shadcn/ui `Dialog` (informational + optional action, not a destructive confirmation — `AlertDialog` is not required here)

**Password Policy (MANDATORY — default unless told otherwise)** - Use Cognito's **default** password policy (minimum length 8, requires lowercase/uppercase/numbers/symbols per Cognito's standard defaults) for every new user pool:

- Do NOT override `password_policy` on the `UserPool` construct unless a developer explicitly requests different rules
- If a developer asks for different requirements (e.g., longer minimum, no symbol requirement), apply exactly what they specify — don't guess a "more secure" policy on your own initiative
- This mirrors the DynamoDB-encryption and MFA defaults elsewhere in this doc: omit the override, trust the service default, unless explicitly told to change it

**Passkey Relying Party ID (MANDATORY — prevents "No relying party Id or domain configured for the user pool")** - This error means the `UserPool` construct never received a passkey relying-party (RP) ID — it has no default, so passkey auth is unusable until it's set explicitly:

- **Always set `passkey_relying_party_id` on the `UserPool` construct** — set it to the domain your app authenticates from (typically your Cognito user pool domain, or your custom domain if you have one):
  ```python
  cognito.UserPool(self, "UserPool",
      passkey_relying_party_id="auth.example.com",       # your user pool domain or custom domain
      passkey_user_verification=cognito.PasskeyUserVerification.PREFERRED,
      sign_in_policy=cognito.SignInPolicy(
          allowed_first_auth_factors=cognito.AllowedFirstAuthFactors(password=True, passkey=True),
      ),
      # ... rest of pool config
  )
  ```
- **If the user pool has a custom domain**, the RP ID **must** be the fully-qualified custom domain (e.g., `auth.example.com`), not the Cognito-assigned prefix domain (`your-prefix.auth.us-east-1.amazoncognito.com`) — a mismatch here silently breaks passkey auth for the prefix domain even after RP ID is set. If both a prefix and a custom domain exist and you need the prefix domain's passkey flow to keep working too, explicitly set RP ID to the prefix domain instead.
- **Do this at initial pool creation, not as an afterthought** — passkey auth appearing in the UI without a working RP ID produces this exact runtime error only when a user attempts registration/sign-in, not at `cdk synth`/`deploy` time, so it's easy to ship and only discover in QA or production.
- **Verify the fix**: `aws cognito-idp get-user-pool-mfa-config --user-pool-id <id>` (via `aws-mcp-server`) should return a `WebAuthnConfiguration.RelyingPartyId` matching your domain — if it's empty, the CDK prop didn't apply (check for a stale deploy) or wasn't set at all.

**API Gateway Integration** - Configure Bearer token auth with JWT validation

## Security

**S3 Buckets** - Avoid public access:

- Prefer CloudFront with Origin Access Control (OAC) for public content — never use OAI (deprecated)
- Block ALL public access on S3 buckets serving via CloudFront
- Use API Gateway with authentication for dynamic access

**Lambda Functions** - Avoid Lambda function URLs:

- Prefer API Gateway with proper authentication
- Implement authorization at API Gateway level

## Deployment

**Infrastructure as Code** - All changes via CDK code, React code, and the `deploy.sh` script.

**`deploy.sh` is the ONLY supported deployment mechanism** - Never deploy via `cdk deploy` directly, the AWS Console, or any other path.

Every project MUST have a `deploy.sh` script at the project root that follows this exact contract:

#### Required Flags

| Flag               | Required                         | Purpose                                                    |
| ------------------ | -------------------------------- | ---------------------------------------------------------- |
| `--profile <name>` | Optional (defaults to `default`) | AWS profile to use                                         |
| `--domain <fqdn>`  | Optional                         | Custom domain for the deployment (e.g. `app.example.com`)  |
| `--delete`         | Optional                         | Tear down the stack AND deep-clean associated resources    |
| `-y` / `--yes`     | Optional                         | Auto-confirm — skip every interactive prompt (deletes too) |
| `-h` / `--help`    | Optional                         | Show usage                                                 |

Examples:

```bash
./deploy.sh                                        # Uses default profile + last-saved domain (if any)
./deploy.sh --domain d1.example.com                # Saves d1 against the default profile
./deploy.sh --domain d2.example.ca --profile work  # Saves d2 against the 'work' profile
./deploy.sh --profile work                          # Reuses d2 (saved earlier)
./deploy.sh --delete                                # Tears down with confirmation prompt
./deploy.sh --delete -y                             # Tears down without prompting
```

#### Per-profile State (MANDATORY)

`deploy.sh` MUST persist non-profile inputs (currently `--domain`, plus any future named flags) keyed by AWS profile, so subsequent runs auto-fill them.

- Storage: `.deploy-state.json` at the project root, gitignored.
- Format: a JSON object keyed by profile name, value is an object of saved inputs.
- Special-case: when no `--profile` is passed, the key is the literal string `default`.
- Read order on each run: CLI flag → saved state for that profile → error if neither and the value is required for the operation.
- Write: every successful invocation that received a non-profile flag MUST update the saved value for that profile before exiting.
- Add `.deploy-state.json` to the project's `.gitignore` — it can leak deployment topology (domains, environment hints) across forks.

Example:

```json
{
  "default": { "domain": "d1.example.com" },
  "work": { "domain": "d2.example.ca" },
  "demo": { "domain": "demo.kiro.dev" }
}
```

#### Deep-Cleanup on `--delete` (MANDATORY)

`cdk destroy` leaves orphans. `deploy.sh --delete` MUST go further:

- Empty and delete every S3 bucket created by the stack (CDK won't delete non-empty buckets even with `RemovalPolicy.DESTROY`)
- Delete every CloudWatch log group created by the stack (Lambda log groups, API GW access logs, custom log groups)
- Remove DNS records the stack added to a shared Route53 hosted zone (without deleting the zone itself — see "Multi-project Safety" below)
- Delete ACM certificates created exclusively for this stack
- Delete any SQS queues, SNS topics, EventBridge rules, ECR repos that the stack owns
- Detach and delete IAM roles + policies the stack created
- Wait for `DELETE_COMPLETE` before exiting; surface any `DELETE_FAILED` resources clearly so the user can intervene

Tag-based discovery is the safest sweep — every stack tags resources with `project=<name>` (the same tag the stack's AWS Resource Group is built on). Use that tag to find resources that survived `cdk destroy`.

#### `-y` Auto-Confirm Flag (MANDATORY)

When `-y` is set, the script MUST NOT issue any interactive prompts. This includes:

- The "are you sure you want to destroy this stack?" prompt on `--delete`
- `cdk deploy --require-approval never` (CDK's own confirmation)
- Any `read -p` prompts the script adds for safety

`-y` is intended for CI-like usage and the `master-demo` agent. Without `-y`, the script SHOULD prompt at every destructive step.

#### Multi-Project Safety in Shared AWS Accounts (MANDATORY)

The same AWS account often hosts multiple projects sharing infrastructure (Route53 hosted zones, ACM certs, VPCs, Cognito user pools). The `deploy.sh` script MUST NOT break sibling projects:

- **Discover by tag, not by name pattern.** Use the `project=<name>` tag (the same tag the stack's AWS Resource Group is built on) to identify resources owned by THIS stack. Never delete resources matching a name prefix or substring — name collisions across projects are real.
- **Touch shared zones surgically.** When this stack created records in a Route53 hosted zone owned by another project (or by a shared infra stack), delete only the records this stack added (typically by `name` + `type`). Never delete the hosted zone itself unless this stack owns it end-to-end.
- **Pre-flight check on `--delete`.** Before destroying, list all resources tagged with this project's tag and show them to the user (or skip the listing under `-y`). Resources NOT tagged with this project are NEVER touched.
- **Shared certificates.** ACM certs in `us-east-1` are commonly reused (CloudFront only accepts certs there). If the cert was imported by another stack, this stack MUST NOT delete it on teardown — even if it imported the cert via `Certificate.fromCertificateArn`. Delete-on-teardown applies only to certs this stack created.
- **CDK bootstrap stack.** `CDKToolkit` is shared across all CDK projects in the account. Never destroy it from `deploy.sh --delete`.

The script handles: `cdk synth`, `cdk diff`, `cdk deploy`, frontend build + S3 sync, CloudFront invalidation, post-deploy state save. Reference template: `skills/deploy.sh.template`.

Never make manual changes in AWS Console.

**No Hardcoded Values (default)** - Prefer SSM Parameter Store (`SecureString` for secrets) by default; use AWS Secrets Manager only when rotation, RDS/Aurora credentials, or an AWS service integration requires it (see `security-policies.md`). Environment variables are for non-secret config only. **Exception:** in a private, single-owner repo, the user may opt into committing plaintext secrets/config — honor it per `security-policies.md` → "Committing Secrets in Private Repos".

**Post-Deployment Testing** - Always:

1. Execute live tests against deployed endpoints
2. Verify expected responses and status codes
3. Check application logs for errors

## Reference Files

- CDK stack examples: #[[file:cdk-backend/cdk/stack.py]]
- Lambda function templates: #[[file:cdk-backend/lambda/functions/example/example.py]]
- React component patterns: #[[file:frontend/src/components/ui/Button.tsx]]
- Environment config: #[[file:.env.example]]
- API specifications: #[[file:api/openapi.yaml]]

## Lambda Resilience

- All async Lambda invocations MUST have a Dead Letter Queue (SQS DLQ)
- Implement idempotency using Lambda Powertools `@idempotent` decorator
- Use exponential backoff for retries to downstream services
- Set reserved concurrency to prevent runaway scaling
- Set timeout to 2x the expected p99 duration (never use the 15-minute max)
- Use Lambda Layers for shared dependencies (Powertools, common utilities). Keep individual function packages small (<5MB unzipped) for faster cold starts.

## Error Handling

**Lambda Functions** - Return structured error responses:

```python
return {
    "statusCode": 400,
    "body": json.dumps({
        "error": "ValidationError",
        "message": "Invalid input parameters",
        "requestId": context.aws_request_id
    })
}
```

**API Gateway** - Configure error mapping for consistent responses

**React Components** - Use error boundaries for graceful failure handling
