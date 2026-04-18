---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
---

# AWS Development Standards

## CDK Infrastructure

**Language Requirement** - ALL CDK code MUST be written in Python. No TypeScript CDK. Lambda functions in Python.

**Resource Tagging** - Tag ALL resources in every stack (mandatory):

```python
from aws_cdk import Tags
Tags.of(stack).add('auto-stop', 'false')
Tags.of(stack).add('auto-delete', 'false')
Tags.of(stack).add('project', project_name)
```

**Stack Naming** - NEVER use default CDK stack names (`CdkStack`, `CdkBackendStack`, `Stack`). Every stack MUST have a unique, project-specific name that clearly identifies the application and environment (e.g., `InvoiceAppDevStack`, `AccountingProdStack`).

**Security Validation** - Always include cdk-nag:

```python
from cdk_nag import AwsSolutionsChecks
from aws_cdk import Aspects
Aspects.of(app).add(AwsSolutionsChecks())
```

**AWS AppRegistry** - Every CDK app MUST register itself in Service Catalog App Registry. This groups all resources under a named application for governance, cost tracking, and operational visibility.

Use the `ApplicationAssociator` pattern in `app.py` — it auto-associates every stack in the app and handles cross-account sharing. The manual `Application` + `associate_application_with_stack` pattern is older and more verbose.

> Note: The module is still in alpha (`aws_servicecatalogappregistry_alpha`) as of CDK 2.248+. Before using, check latest AWS CDK docs via the Microsoft Learn / AWS documentation MCP server to see if it has graduated to stable (`aws_cdk.aws_servicecatalogappregistry`).

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

**Lambda Functions** - Use `PythonFunction` construct with Python 3.13:

```python
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime

PythonFunction(self, 'MyFunction',
    runtime=Runtime.PYTHON_3_13,
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

**deploy.sh is the ONLY deployment method** - Never deploy via `cdk deploy` directly or the AWS Console.

- Every project MUST have a `deploy.sh` script at the project root
- Required flags:
  - `--profile <name>` — AWS profile to use (no default, must be explicit)
  - `--delete` — Tear down the stack (destroy all resources)
- The script handles: `cdk synth`, `cdk diff`, `cdk deploy`, frontend build + S3 sync
- Example: `./deploy.sh --profile my-dev` or `./deploy.sh --profile my-dev --delete`

Never make manual changes in AWS Console.

**No Hardcoded Values** - Use environment variables, SSM Parameter Store, or Secrets Manager

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
