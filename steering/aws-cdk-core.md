---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
name: aws-cdk-core
description: 'AWS CDK core standards: Python only (never TypeScript), alpha module graduation checks, L2/L3 construct preference, resource tagging, stack naming, cdk-nag, AWS Resource Groups (tag-based, replaces AppRegistry), DynamoDB GSI limits + mandatory AWS-owned-key encryption, S3 bucket naming. Use when writing or reviewing CDK infrastructure code.'
---

# AWS CDK Core Standards

> When uncertain about an AWS service, API, IAM action, or limit, resolve and call the AWS docs-search / skill-retrieval tools (`search_documentation`, `retrieve_skill`) from the `aws-mcp-server` MCP server — see `steering/aws-agent-toolkit.md` → "Resolving the correct tool name" if the literal tool name doesn't resolve on first try.

## Language and Construct Level

**Language Requirement** - ALL CDK code MUST be written in Python. No TypeScript CDK. Lambda functions in Python.

**CDK Alpha Modules** - Before using any `*_alpha` CDK module, check whether it has graduated to stable in `aws-cdk-lib`. Alpha modules are separate `pip` packages (`aws-cdk.aws-<service>-alpha`) with no backward-compatibility guarantee; most eventually graduate into `aws-cdk-lib` and the alpha package is then deprecated.

- **Prefer the stable module when one exists** — stable constructs live in `aws-cdk-lib`, importing as `from aws_cdk import aws_<service>`.
- It's fine to use an alpha module when the stable path doesn't exist yet or is missing features the alpha has. Verify current status via the AWS docs-search tool or the module's PyPI page before choosing it.
- **Re-check every alpha module already in use** as part of the daily-maintenance dependency upgrade (`development-quality-gates.md`) — migrate to stable in the same pass if it has graduated.
- If the PyPI page says "deprecated / moved to aws-cdk-lib" or Development Status is "Inactive", the alpha is dead; use the stable path immediately.
- **Known graduation**: `aws-cdk.aws-apigatewayv2-alpha` → deprecated Dec 2023. Use `aws_cdk.aws_apigatewayv2`, `aws_apigatewayv2_integrations`, `aws_apigatewayv2_authorizers` (all now in `aws-cdk-lib`).
- **Currently in active use, still alpha** (verified at CDK **2.260.0**, Development Status: Beta; re-check on next upgrade): `aws_lambda_python_alpha` (`PythonFunction`). We no longer use `aws_servicecatalogappregistry_alpha` — see "AWS Resource Groups" below.

**Construct Level (MANDATORY) — prefer L2/L3 over L1** - Always use the highest-level construct available. Prefer **L3** (patterns) and **L2** (curated resources with sensible defaults) over **L1** (`Cfn*`, raw CloudFormation 1:1).

- Whenever guidance or generated code reaches for an **L1 `Cfn<Resource>`**, first verify whether `aws-cdk-lib` now ships an L2/L3 for that resource, and propose the higher-level construct instead.
- Only fall back to L1 when no L2/L3 exists. When you do, leave a short comment saying so.
- Re-check on every CDK upgrade — L2s graduate continuously.
- Current known L1-only exception: **`aws_resourcegroups.CfnGroup`** — no L2 exists as of CDK 2.260; re-check on upgrade.

## Resource Tagging and Stack Naming

**Resource Tagging** - Tag ALL resources in every stack (mandatory):

```python
from aws_cdk import Tags
Tags.of(stack).add('auto-stop', 'false')
Tags.of(stack).add('auto-delete', 'false')
Tags.of(stack).add('project', project_name)
```

**Stack Naming** - NEVER use default CDK stack names (`CdkStack`, `CdkBackendStack`, `Stack`). Every stack MUST have a unique, project-specific name identifying the application and environment (e.g., `InvoiceAppDevStack`, `InvoiceAppProdStack`).

**Security Validation** - Always include cdk-nag:

```python
from cdk_nag import AwsSolutionsChecks
from aws_cdk import Aspects
Aspects.of(app).add(AwsSolutionsChecks())
```

## AWS Resource Groups (MANDATORY)

Every CDK app MUST register its resources in a **tag-based AWS Resource Group** for governance, cost tracking, and operational visibility.

> **Why not Service Catalog AppRegistry / myApplications?** Per the AWS announcement on 2026-06-30, AppRegistry and the myApplications console moved to **maintenance** (effective 2026-07-30: no new applications or updates). AWS recommends **AWS Resource Groups** (tag-based) as the replacement. Do NOT use `ApplicationAssociator` / `aws_servicecatalogappregistry_alpha` in new code.

Resource Groups uses the **stable** `aws_cdk.aws_resourcegroups.CfnGroup` (`AWS::ResourceGroups::Group`) — no alpha package required, built from the mandatory `project` tag every stack already applies:

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
Tags.of(stack).add('project', project_name)
app.synth()
```

Rules:

- The group is **tag-based on `project=<name>`** — no `awsApplication` tag, no AppRegistry application.
- `name` should be unique per account per region (e.g., `{project}-{region}`).
- `resource_type_filters=['AWS::AllSupported']` includes every taggable resource type; narrow it only if you want a subset.
- Resource Groups are Region-scoped — create one per region you deploy to.
- Do NOT rely on Resource Groups – Group Lifecycle Events (also moved to maintenance 2026-06-30); plain tag-based groups are fully supported.

### Migrating an existing project off myApplications / AppRegistry (NON-DESTRUCTIVE)

If a project still uses `ApplicationAssociator` / AppRegistry, migrate to a tag-based Resource Group. **This migration MUST be non-destructive** — it changes only the _grouping_ mechanism; workload resources (Lambda, log groups, S3, DynamoDB/RDS/Aurora, SQS, etc.) MUST NOT be deleted.

Why it's safe: deleting the AppRegistry **Application** removes only the Service Catalog registry entry and its resource associations, not the associated workload resources. Removing the `awsApplication` tag is metadata-only.

Procedure:

1. **Add the Resource Group** (the `CfnGroup` above) and ensure every stack applies the `project` tag. Deploy. Confirm the new group lists the expected resources (`aws resource-groups list-group-resources --group-name <name>`, via `aws-mcp-server`).
2. **Remove the AppRegistry wiring** — delete the `ApplicationAssociator` block (and the alpha dependency) from `app.py`. On the next deploy, CloudFormation deletes only the AppRegistry **Application** (and its separate `*-AppRegistry-*` stack, if any) — NOT the workload stacks.
3. **Drop the `awsApplication` tag only if nothing else uses it** — optional, metadata-only if removed.
4. **Never `cdk destroy`, never empty/delete S3 buckets, never delete log groups, queues, or databases as part of this migration.** If `deploy.sh --delete` exists, do NOT run it — migration is a deploy, not a teardown.
5. **Verify post-migration**: workload resources still exist and function, the Resource Group shows them, and the old AppRegistry application is gone (or intentionally left).

> Guardrail: if ever unsure whether a migration step would delete a workload resource, STOP and ask the user. The only things this migration may remove are the AppRegistry Application and the (now-unused) `awsApplication` tag.

## Lambda Functions

Use `PythonFunction` construct with Python 3.14:

```python
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime

PythonFunction(self, 'MyFunction',
    runtime=Runtime.PYTHON_3_14,
    entry='cdk-backend/lambda/functions/my_function',
    index='my_function.py'
)
```

## DynamoDB

**GSI creation/deletion limits** - Only add/remove ONE GSI per `cdk deploy`. Wait for deployment completion before the next GSI change.

**Encryption (MANDATORY — ALWAYS DEFAULT, NEVER CHANGE)** - Every DynamoDB table MUST use DynamoDB's default encryption (AWS-owned key). Non-negotiable:

- **Do NOT set `encryption=` on `dynamodb.Table` / `dynamodb.TableV2` at all.** Omit the parameter — CDK's default is `TableEncryption.AWS_OWNED`, which is correct.
- **NEVER set `encryption=dynamodb.TableEncryption.AWS_MANAGED` or `CUSTOMER_MANAGED`** on any DynamoDB table, in any project, for any reason — switching modes only adds KMS cost, complexity, and IAM/key-policy surface area with no security benefit here.
- This is a deliberate **exception** to the general "encrypt everything with KMS" rule (`security-policies.md`) — DynamoDB is excluded by design. S3, SQS, SNS, and EBS still use KMS.
- If a CDK diff or review shows `encryption=` being added to a DynamoDB table construct, treat it as a regression — remove the parameter, don't change its value.
- Applies identically to CloudFormation (omit `SSESpecification`, or if present, do not set `SSEType`/`KMSMasterKeyId`) and any other IaC tooling.

## S3 Buckets

Let CDK auto-generate names, avoid the `bucket_name` parameter. Security rules (public access, OAC): `security-policies.md`.
