---
name: aws-serverless-patterns
description: AWS Lambda, API Gateway, DynamoDB, Step Functions, EventBridge patterns and best practices. Use when building or reviewing serverless backends, CDK infrastructure, or Lambda functions.
---

# AWS Serverless Patterns

## Lambda Function Template
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
    logger.info("Processing request", extra={"request_id": context.aws_request_id})
    metrics.add_metric(name="RequestProcessed", unit="Count", value=1)
    return {"statusCode": 200, "body": json.dumps({"status": "success"})}
```

## CDK Lambda Pattern
```python
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime, Tracing

PythonFunction(self, 'MyFunction',
    runtime=Runtime.PYTHON_3_13,
    entry='cdk-backend/lambda/functions/my_function',
    index='my_function.py',
    tracing=Tracing.ACTIVE,
    memory_size=512,
    timeout=Duration.seconds(30),
)
```

## DynamoDB Single-Table Pattern
- PK: `ENTITY#id` (e.g., `USER#123`, `ORDER#456`)
- SK: `METADATA` for base item, `RELATION#id` for relationships
- GSI1PK/GSI1SK for secondary access patterns
- Always use on-demand billing for variable workloads
- Enable point-in-time recovery

## API Gateway Pattern
- REST API with Cognito authorizer
- Request validation models at gateway level
- Defense in depth: validate again in Lambda with pydantic
- CORS: explicit origins, never `*` in production

## Step Functions Pattern
- Express workflows for synchronous, high-volume (<5 min)
- Standard workflows for long-running, auditable processes
- Always enable X-Ray tracing
- Use DLQ for failed executions

## Error Response Pattern
```python
return {
    "statusCode": 400,
    "body": json.dumps({
        "error": {"code": "VALIDATION_ERROR", "message": "Invalid input"},
        "meta": {"requestId": context.aws_request_id}
    })
}
```
