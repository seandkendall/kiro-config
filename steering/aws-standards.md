---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
name: aws-standards
description: AWS development standards: CDK Python (never TypeScript), resource tagging, cdk-nag, AppRegistry, Lambda Powertools, Cognito custom UI + passkeys, S3 OAC, Lambda resilience (DLQ + idempotency), API routing through CloudFront /api path. Use when writing or reviewing CDK, Lambda, or AWS infrastructure code.
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
- **Still alpha** (verified at CDK **2.260.0** on 2026-06-23 — both publish as `2.260.0a0`, Development Status: Beta; re-check before relying on it): `aws_lambda_python_alpha` (`PythonFunction`), `aws_servicecatalogappregistry_alpha` (`ApplicationAssociator`). These have NOT graduated — the alpha package is still required.

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

**AWS AppRegistry** - Every CDK app MUST register itself in Service Catalog App Registry. This groups all resources under a named application for governance, cost tracking, and operational visibility.

Use the `ApplicationAssociator` pattern in `app.py` — it auto-associates every stack in the app and handles cross-account sharing. The manual `Application` + `associate_application_with_stack` pattern is older and more verbose.

> Note: The module is still in alpha (`aws_servicecatalogappregistry_alpha`) as of CDK 2.260 (verified 2026-06-23). Before using, check latest AWS CDK docs via the AWS documentation MCP server to see if it has graduated to stable (`aws_cdk.aws_servicecatalogappregistry`).

Install:

```bash
pip install aws-cdk.aws-servicecatalogappregistry-alpha
```

Register in `app.py`:

```python
import os
import aws_cdk as cdk
from aws_cdk import aws_servicecatalogappregistry_alpha as appreg

app = cdk.App()
region = os.environ.get('CDK_DEFAULT_REGION', 'us-east-1')
project_name = 'MyApp'

# Auto-associates all stacks in this app with the AppRegistry application.
# The awsApplication tag is automatically propagated to every resource.
appreg.ApplicationAssociator(app, 'AppRegistry',
    applications=[appreg.TargetApplication.create_application_stack(
        application_name=f'{project_name}-{region}',
        stack_name=f'{project_name}-AppRegistry-{region}',
        application_description=f'{project_name} deployed in {region}',
        associate_cross_account_stacks=True,
    )]
)

# Define your stacks AFTER ApplicationAssociator
MyAppStack(app, f'{project_name}Stack-{region}', ...)

app.synth()
```

Rules:

- `application_name` MUST be unique per account per region and is immutable once created
- Place the `ApplicationAssociator` BEFORE any stack definitions in `app.py`
- Do NOT manually add the `awsApplication` tag — `ApplicationAssociator` propagates it automatically to every resource in every associated stack
- For cross-account deployments (e.g., pipeline target accounts), set `associate_cross_account_stacks=True`

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

- Custom **login page** with email/password + passkey support
- Custom **registration page** with email verification
- Custom **password reset page** (forgot password flow)
- Use the Cognito Identity SDK or `amazon-cognito-identity-js` / `@aws-amplify/auth` for all auth flows

**Custom Cognito Emails (MANDATORY)** - NEVER use the default Cognito verification, password-reset, or MFA emails. Wire up the `CustomEmailSender` Lambda trigger and send brand-matched HTML via SES. Full rule: `email-standards.md`.

**Passkeys (MANDATORY)** - ALWAYS enable WebAuthn/passkeys for login:

- Passkeys MUST be offered as a primary login method — not hidden behind email entry
- Users should see a "Sign in with passkey" button immediately on the login page (no email-first flow)
- After login, users MUST be able to add multiple passkeys from their account settings (any number of devices)
- Use Cognito's WebAuthn support with `USER_AUTH` flow and `WEB_AUTHN` challenge
- Passkey registration: allow users to name each passkey (e.g., "MacBook Pro", "iPhone 15")
- Passkey management: list, rename, and delete registered passkeys from account settings

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

Tag-based discovery is the safest sweep — every stack tags resources with `awsApplication` (via AppRegistry's `ApplicationAssociator`) and `project=<name>`. Use those tags to find resources that survived `cdk destroy`.

#### `-y` Auto-Confirm Flag (MANDATORY)

When `-y` is set, the script MUST NOT issue any interactive prompts. This includes:

- The "are you sure you want to destroy this stack?" prompt on `--delete`
- `cdk deploy --require-approval never` (CDK's own confirmation)
- Any `read -p` prompts the script adds for safety

`-y` is intended for CI-like usage and the `master-demo` agent. Without `-y`, the script SHOULD prompt at every destructive step.

#### Multi-Project Safety in Shared AWS Accounts (MANDATORY)

The same AWS account often hosts multiple projects sharing infrastructure (Route53 hosted zones, ACM certs, VPCs, Cognito user pools). The `deploy.sh` script MUST NOT break sibling projects:

- **Discover by tag, not by name pattern.** Use `awsApplication` (set by AppRegistry's `ApplicationAssociator`) and `project=<name>` tags to identify resources owned by THIS stack. Never delete resources matching a name prefix or substring — name collisions across projects are real.
- **Touch shared zones surgically.** When this stack created records in a Route53 hosted zone owned by another project (or by a shared infra stack), delete only the records this stack added (typically by `name` + `type`). Never delete the hosted zone itself unless this stack owns it end-to-end.
- **Pre-flight check on `--delete`.** Before destroying, list all resources tagged with this project's tag and show them to the user (or skip the listing under `-y`). Resources NOT tagged with this project are NEVER touched.
- **Shared certificates.** ACM certs in `us-east-1` are commonly reused (CloudFront only accepts certs there). If the cert was imported by another stack, this stack MUST NOT delete it on teardown — even if it imported the cert via `Certificate.fromCertificateArn`. Delete-on-teardown applies only to certs this stack created.
- **CDK bootstrap stack.** `CDKToolkit` is shared across all CDK projects in the account. Never destroy it from `deploy.sh --delete`.

The script handles: `cdk synth`, `cdk diff`, `cdk deploy`, frontend build + S3 sync, CloudFront invalidation, post-deploy state save. Reference template: `skills/deploy.sh.template`.

Never make manual changes in AWS Console.

**No Hardcoded Values** - Prefer SSM Parameter Store (`SecureString` for secrets) by default; use AWS Secrets Manager only when rotation, RDS/Aurora credentials, or an AWS service integration requires it (see `security-policies.md`). Environment variables are for non-secret config only.

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
