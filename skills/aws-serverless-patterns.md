---
name: aws-serverless-patterns
description: AWS Lambda, API Gateway, DynamoDB, Step Functions, EventBridge patterns and best practices. Use when building or reviewing serverless backends, CDK infrastructure, or Lambda functions.
---

# AWS Serverless Patterns

> When uncertain about an AWS API parameter, IAM action, or service quota, resolve and call the AWS docs-search tool (`search_documentation`) from the `aws-mcp-server` MCP server — see `steering/aws-agent-toolkit.md` → "Resolving the correct tool name" if the literal tool name doesn't resolve on first try. If unsure which MCP tool covers your task, see `skills/mcp-tool-discovery.md` for the discovery flow.

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
    runtime=Runtime.PYTHON_3_14,
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
- **Set CORS headers on every Lambda response, not just the OPTIONS preflight** — if the frontend calls the API cross-origin (no CloudFront routing to API Gateway), a real 4xx/5xx from application code still needs `Access-Control-Allow-Origin` etc. on it or the browser reports it as a CORS failure regardless of the actual status code.
- **A Lambda that throws during cold start (missing import, bad env var, etc.) returns a headerless 502 with no CORS headers at all — this looks exactly like a CORS error in the browser console but isn't one.** If a request that used to work suddenly "fails with CORS" after a deploy, check CloudWatch logs for the function first (`Runtime.ImportModuleError`, unhandled exception in module-scope code) before touching CORS configuration — CORS headers can't be attached to a response the runtime never got a chance to send.

## Step Functions Pattern

- Express workflows for synchronous, high-volume (<5 min)
- Standard workflows for long-running, auditable processes
- Always enable X-Ray tracing
- Use DLQ for failed executions

## EventBridge Pattern

- **A Lambda invoked as an EventBridge rule target receives the full EventBridge envelope, not the raw event you published.** `PutEvents`'s `Detail` field ends up nested at `event["detail"]` on the invocation side — the envelope also carries `version`, `id`, `detail-type`, `source`, `account`, `time`, `region`, `resources`. Reading a top-level key (e.g. `event["itemId"]`) directly on a payload that only exists inside `detail` raises a bare `KeyError` — passes every static check and deploys clean, only surfaces the first time the rule actually fires. Unwrap defensively so the same handler also works for direct/local invocation with the flat payload: `payload = event.get("detail", event)`, then read fields off `payload`.
- Publish one `Source`/`DetailType` naming scheme per event family and keep the rule's `EventPattern` matching on both, not just `DetailType` — an unscoped pattern on a shared bus can match events from other unrelated producers.
- An EventBridge rule targeting a Lambda function needs an explicit `AWS::Lambda::Permission` (`Principal: events.amazonaws.com`, `SourceArn` scoped to the rule's ARN) unless the target's execution role already grants `lambda:InvokeFunction` — SAM does not add this automatically for `AWS::Events::Rule` targets the way it does for `Events:` on `AWS::Serverless::Function`.

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

## Lambda Durable Functions Pattern

```python
from aws_durable_execution_sdk_python import DurableContext, durable_execution
from aws_durable_execution_sdk_python.config import WaitForCallbackConfig, Duration

@durable_execution
def lambda_handler(event: dict, context: DurableContext) -> dict:
    result = context.step(lambda _: do_work(event), name="do-work")

    def submit(callback_id: str, _ctx) -> None:
        notify_external_system(callback_id)

    raw_decision = context.wait_for_callback(
        submitter=submit, name="wait-for-decision",
        config=WaitForCallbackConfig(timeout=Duration.from_days(1)),
    )
    return {"result": result}
```

**A `wait_for_callback()` result is the raw payload exactly as the external caller sent it — never auto-parsed.** `SendDurableExecutionCallbackSuccess`'s `Result` field is an opaque `bytes`/string field, not a structured typed value. If the caller sends `Result=json.dumps({...})`, the workflow's `wait_for_callback()` call returns that exact JSON *string*, not a dict — calling `.get(...)` on it directly raises `AttributeError: 'str' object has no attribute 'get'`. Deserialize it yourself, once, immediately after the call returns:

```python
raw_decision = context.wait_for_callback(...)
decision = json.loads(raw_decision) if isinstance(raw_decision, str) else raw_decision
```

**Never call a durable operation (`context.step`, `context.wait`, `context.invoke`) from inside a `wait_for_callback` submitter — it produces `NonDeterministicExecutionError` on resume, not at deploy time.** The submitter only executes once, when the execution first suspends; on replay after the callback resolves, the SDK expects the exact same operation sequence to reconstruct, and a step nested inside the submitter breaks that sequence. If the submitter needs to persist state (e.g., writing the callback id somewhere an external caller can find it), do that with a plain synchronous call directly in the submitter body — the submitter itself is already checkpointed by `wait_for_callback`, so it doesn't need, and cannot use, a nested `context.step()`:

```python
# WRONG -- nested step inside the submitter, breaks replay
def submit(callback_id: str, ctx) -> None:
    context.step(persist_callback_id(callback_id), name="persist")  # NonDeterministicExecutionError
 
# CORRECT -- plain call, no nested durable operation
def submit(callback_id: str, ctx) -> None:
    persist_callback_id_directly(callback_id)  # ordinary function call, not context.step(...)
```

**A durable execution's `callbackId` goes stale once that execution terminates** (times out, fails, or the callback is already resolved). Any caller invoking `SendDurableExecutionCallbackSuccess`/`Failure` against a stale id gets `CallbackTimeoutException: The callback is either timed out or already completed` — this is a real runtime condition to handle explicitly (mark whatever state referenced that callback as expired/needs-resubmission), not just an error to log and 502 on.

**When a durable execution silently doesn't progress, diagnose with `get-durable-execution-history` before guessing.** This read-only AWS CLI call gives an exact step-by-step timeline with the real error payload for every failed step, callback, or child context — far faster than reasoning from CloudWatch log greps:

```bash
aws lambda get-durable-execution-history \
  --durable-execution-arn <arn> --include-execution-data
```

Never call any `Stop*`/terminate API while diagnosing — this is a read/observe-only operation. See the `aws-lambda-durable-functions` skill's `troubleshooting-executions.md` reference for the full procedure, including how to map event types (`StepFailed`, `CallbackTimedOut`, `ChainedInvokeFailed`, etc.) to root causes.

## SAM Template Gotchas

- **Don't set `Metadata.BuildMethod` on an `AWS::Serverless::LayerVersion` that has no `requirements.txt` — it double-nests the layer's `python/` directory.** SAM's Python layer builder treats a `BuildMethod`-tagged layer as a pip-install target and wraps its `ContentUri` in an extra `python/` on top of whatever structure is already there, producing `python/python/<package>` instead of `python/<package>` (which breaks the import). If the layer is pure code with nothing to `pip install`, omit `Metadata` entirely and lay the source out as `<content-uri>/python/<package>/` directly — SAM copies it as-is with no extra nesting.
- **A function cannot reference its own `AutoPublishAlias` from inside its own `Globals.Function.Environment` block** (or its own per-function `Environment`) — `!Ref MyFunction.Alias` used as an environment variable on `MyFunction` itself is a circular dependency (`sam validate --lint` catches it as `E3004`) because the alias resource depends on the function, and the function's env now depends on the alias. If a *different* function needs that alias ARN (e.g., to invoke it), put the `!Ref MyFunction.Alias` env var on that other function, never on the function defining the alias.

## Known Gotchas (found only by real invocation, not static validation)

These will pass `sam validate`, a clean build, and a successful deploy every time — they only surface when the deployed function is actually invoked with real input. Check for all of them proactively; do not wait to rediscover them per project.

- **A specific Bedrock model ID may not be invokable on-demand.** Some models reject direct on-demand invocation by bare model ID with `ValidationException: ... on-demand throughput isn't supported. Retry your request with the ID or ARN of an inference profile`. Check `aws bedrock list-inference-profiles` for a matching `us.<model-id>` or `global.<model-id>` entry and use that as the Converse/InvokeModel `modelId` instead — it's the correct invocation identifier for the same model, not a different model, and the fix is to find that identifier, not to substitute a different model or fall back to a workaround. IAM must then grant `bedrock:InvokeModel`/`Converse` on both the inference profile ARN and every underlying foundation-model ARN it can route to (`aws bedrock get-inference-profile --query 'models[].modelArn'` — a cross-region profile routes to multiple regions, each needs its own ARN in the policy).
- **Bedrock model-specific `inferenceConfig` parameter support varies by model generation — don't assume a field like `temperature` is universally accepted.** A value that worked on one model can be rejected outright on another with `ValidationException: ... 'temperature' is deprecated for this model.` Remove or adjust the specific offending field rather than assuming the whole call shape is wrong.
- **`boto3.resource("dynamodb")` rejects native Python `float` values outright** with `TypeError: Float types are not supported. Use Decimal types instead.` Any numeric value that originated from JSON (an LLM's structured output, an API request body, any `json.loads`) is a plain `float` and will crash a `put_item`/`update_item` call. Recursively convert floats to `decimal.Decimal(str(value))` (via `str()`, not the float directly, to avoid binary-float imprecision) in a single shared write helper used by every call site — not patched in per call site, since every current and future numeric field is at risk.
- **`sam deploy --parameter-overrides` truncates a value at the first whitespace, even when the whole `ParameterKey=...,ParameterValue="..."` argument is shell-quoted.** A value containing a space (e.g. an `Authorization: Basic <token>`-style header) needs an *extra* layer of single quotes around the value itself: `"ParameterKey=Foo,ParameterValue='value with spaces'"`. Without it, everything after the first space is silently dropped — no error, exit code 0, a successfully deployed but truncated parameter. Verify with `sam deploy --debug ... --no-execute-changeset 2>&1 | grep parameter_overrides` before trusting any deploy that sets a space-containing parameter.
