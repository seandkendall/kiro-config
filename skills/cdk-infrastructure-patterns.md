---
name: cdk-infrastructure-patterns
description: AWS CDK Python patterns for stacks, constructs, tagging, cdk-nag, CloudFront, Cognito, S3. Use when writing or reviewing CDK infrastructure code.
---

# CDK Infrastructure Patterns

> When uncertain about a CloudFormation/CDK construct, IAM action, or service limit, use `aws___search_documentation` and `aws___retrieve_skill` from the `aws-mcp-server` MCP server. If unsure which MCP tool to invoke, see `skills/mcp-tool-discovery.md` for the discovery flow.

## Stack Template

```python
from aws_cdk import Stack, Tags, Aspects, Duration
from cdk_nag import AwsSolutionsChecks

class MyAppStack(Stack):
    def __init__(self, scope, construct_id, **kwargs):
        super().__init__(scope, construct_id, **kwargs)
        Tags.of(self).add('auto-stop', 'false')
        Tags.of(self).add('auto-delete', 'false')
        Tags.of(self).add('project', 'my-app')
```

## App Entry Point

```python
app = cdk.App()
stack = MyAppStack(app, "MyAppDevStack", env=cdk.Environment(account="123456789", region="us-east-1"))
Aspects.of(app).add(AwsSolutionsChecks())
app.synth()
```

## CloudFront + S3 (OAC, not OAI)

```python
distribution = cloudfront.Distribution(self, "CDN",
    default_behavior=cloudfront.BehaviorOptions(
        origin=origins.S3BucketOrigin.with_origin_access_control(bucket),
        viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    ),
    default_root_object="index.html",
    error_responses=[cloudfront.ErrorResponse(http_status=404, response_page_path="/index.html", response_http_status=200)],
)
```

## Cognito

```python
user_pool = cognito.UserPool(self, "UserPool",
    self_sign_up_enabled=True,
    sign_in_aliases=cognito.SignInAliases(email=True),
    mfa=cognito.Mfa.REQUIRED,
    managed_login_version=cognito.ManagedLoginVersion.NEWER_MANAGED_LOGIN,
)
```

## DynamoDB

```python
table = dynamodb.Table(self, "Table",
    partition_key=dynamodb.Attribute(name="PK", type=dynamodb.AttributeType.STRING),
    sort_key=dynamodb.Attribute(name="SK", type=dynamodb.AttributeType.STRING),
    billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
    point_in_time_recovery=True,
    encryption=dynamodb.TableEncryption.AWS_MANAGED,
)
```

## Rules

- NEVER use default stack names (CdkStack, Stack)
- Let CDK auto-generate S3 bucket names
- Only add/remove ONE GSI per deploy
- Always include cdk-nag AwsSolutionsChecks
- deploy.sh is the ONLY deployment method
