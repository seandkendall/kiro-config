---
name: openobserve-telemetry
description: Instruments AWS serverless projects (API Gateway, Lambda, DynamoDB) to send full OpenTelemetry data — traces, metrics, and logs — to the shared OpenObserve instance on this account. Covers ADOT Lambda layer setup, OTLP endpoint (derived live from CloudFormation) and auth (single SSM SecureString parameter), API Gateway trace continuity (requires X-Ray propagation, not X-Ray as a backend), CloudWatch→Firehose log delivery, naming/tagging conventions, sampling, account-specific constraints (7-day retention, late/future data rejection), and a definition-of-done checklist. Use whenever building or reviewing observability for a Lambda/API Gateway/DynamoDB serverless project on this account. NOT for other OpenTelemetry backends or accounts — this skill documents one specific, verified OpenObserve deployment.
version: 1
metadata:
  service: [lambda, api-gateway, dynamodb, cloudwatch, ssm, cloudformation]
  task: [instrument, deploy, debug, configure]
  persona: [developer, devops]
  workload: [serverless, observability]
---

**IMPORTANT**: This skill documents one specific, live OpenObserve deployment on this account. Every endpoint, credential path, and payload shape below was verified against the real instance. Treat the connection details as authoritative for this account — do not substitute a different OTel backend or invent endpoints. If a value below (URL, parameter path, credential) appears to have changed, re-verify against the live stack (see section 1) rather than guessing.

## Table of Contents

1. Connection details (single SSM parameter for auth; endpoint derived from CloudFormation)
2. Verify connectivity first
3. Lambda instrumentation (ADOT layer, env vars, manual spans, cold starts)
4. API Gateway (access logs + trace continuity — requires X-Ray propagation)
5. Logs (CloudWatch→Firehose vs. OTLP direct)
6. Naming and tagging
7. Account-specific constraints (retention, sampling, VPC egress)
8. Definition of done
9. Troubleshooting

---

## 1. Connection details

| Setting          | Value                                                                                                  |
| ---------------- | ------------------------------------------------------------------------------------------------------ |
| Base URL         | A CloudFront domain — re-derive from CloudFormation, do not hardcode or cache indefinitely (see below) |
| Organisation     | `default` — fixed constant, not configurable, not stored anywhere                                      |
| Traces endpoint  | `POST /api/default/v1/traces`                                                                          |
| Metrics endpoint | `POST /api/default/v1/metrics`                                                                         |
| Logs endpoint    | `POST /api/default/v1/logs`                                                                            |
| Protocol         | **OTLP over HTTP** (`application/json` or `application/x-protobuf`)                                    |
| Auth             | HTTP Basic, `Authorization: Basic <base64(email:password)>`                                            |

### Credentials — one SSM parameter, never hardcoded

Only the auth token is stored in SSM. There is no SSM parameter for the endpoint or the org — see why below.

- **`/openobserve/otlp-basic-token`** (`SecureString`) — the pre-computed `Authorization: Basic <token>` value for the dedicated `otel-ingest` account user (not root — see below). Read with `aws ssm get-parameter --name /openobserve/otlp-basic-token --with-decryption`, and set as `OTEL_EXPORTER_OTLP_HEADERS` formatted `Authorization=Basic <token>`.

To create it:

```bash
aws ssm put-parameter --name /openobserve/otlp-basic-token --type SecureString \
  --value '<base64(email:password)>' \
  --region us-east-1
```

A dedicated ingest user exists for telemetry (`otel-ingest@...`) rather than using the root login. On this account's OpenObserve tier (OSS build), fine-grained roles are rejected, so this user carries the `admin` role — it is not least-privilege, only a way to avoid handing out root and to allow revocation without rotating root credentials. Treat the token accordingly (SecureString, never logged, never printed).

**Residual exposure to be aware of:** the OTel SDK reads its auth from the `OTEL_EXPORTER_OTLP_HEADERS` environment variable, and Lambda environment variables are visible via `GetFunctionConfiguration` and in CloudFormation. Acceptable for this account's current use. If this pattern moves to a stricter production posture, fetch the token at cold start with the Lambda Powertools `parameters` utility and configure the exporter in code instead of via a plain environment variable.

### The base URL is NOT stored in SSM — derive it from CloudFormation

It is a CloudFront domain, not a custom domain. If that distribution is ever recreated the hostname changes — this is why it is looked up live rather than cached in SSM or pasted into code:

```bash
aws cloudformation describe-stacks --region us-east-1 \
  --stack-name OpenObserveEksDemoStack-us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='OpenObserveUrl'].OutputValue" --output text
```

Run this lookup at the start of each build/deploy session (or in a deploy script) and use the result directly for `OTEL_EXPORTER_OTLP_ENDPOINT` (append `/api/default` — the SDK appends the signal path itself). Do not add a new SSM parameter for this value; that would just be a second, potentially stale copy of what CloudFormation already has authoritatively.

You must go through CloudFront — the load balancer behind it only accepts traffic from CloudFront's origin-facing prefix list. There is no direct path to the cluster.

---

## 2. Verify connectivity first

Do this before writing any instrumentation. It takes 30 seconds and removes all ambiguity about whether a later problem is auth, networking, or application code.

```bash
TOKEN=$(aws ssm get-parameter --name /openobserve/otlp-basic-token --with-decryption \
  --query Parameter.Value --output text)
URL=$(aws cloudformation describe-stacks --region us-east-1 \
  --stack-name OpenObserveEksDemoStack-us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='OpenObserveUrl'].OutputValue" --output text)
NOW=$(( $(date +%s) * 1000000000 ))

curl -s -w '\n%{http_code}\n' -X POST \
  -H "Authorization: Basic ${TOKEN}" \
  -H 'Content-Type: application/json' \
  "${URL}/api/default/v1/traces" \
  -d "{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",
      \"value\":{\"stringValue\":\"connectivity-check\"}}]},\"scopeSpans\":[{\"spans\":
      [{\"traceId\":\"5b8aa5a2d2c872e8321cf37308d69df2\",\"spanId\":\"051581bf3cb55c13\",
      \"name\":\"check\",\"kind\":2,\"startTimeUnixNano\":\"${NOW}\",
      \"endTimeUnixNano\":\"$(( NOW + 1000000 ))\",\"status\":{\"code\":1}}]}]}]}"
```

Expect `200` and `{"partialSuccess":null}`. Then find it in the OpenObserve UI under **Traces**.

---

## 3. Lambda instrumentation

Use the **AWS Distro for OpenTelemetry (ADOT) Lambda layer** for auto-instrumentation, then point the OTel SDK straight at OpenObserve with standard environment variables. No collector configuration file is needed for this setup.

### 3.1 Add the layer

Get the current ARN for your region and runtime from the [ADOT Lambda layer documentation](https://aws-otel.github.io/docs/getting-started/lambda) and **pin the version** — do not track latest. Confirm the current ARN via the AWS docs-search tool (resolve the callable name via `tool_search` first — see `steering/aws-agent-toolkit.md`) before using it, since these are updated periodically. Example (SAM, illustrative — verify the pinned ARN before use):

```yaml
Layers:
  - arn:aws:lambda:us-east-1:901920570463:layer:aws-otel-python-amd64-ver-1-32-0:1
```

### 3.2 Environment variables

The endpoint value comes from the CloudFormation lookup in section 1 (pass it in as a SAM parameter override, e.g. `--parameter-overrides OtelEndpoint=$(aws cloudformation describe-stacks ...)`), not a dynamic SSM reference — only the auth header is stored in SSM.

```yaml
Environment:
  Variables:
    # Activates ADOT auto-instrumentation.
    AWS_LAMBDA_EXEC_WRAPPER: /opt/otel-instrument

    # Ship straight to OpenObserve over OTLP/HTTP.
    OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
    # Resolved from the CloudFormation OpenObserveUrl output + "/api/default" — pass as a SAM parameter, do not hardcode.
    OTEL_EXPORTER_OTLP_ENDPOINT: !Ref OtelEndpointParameter
    # Resolved from SSM — the only value that lives in Parameter Store.
    OTEL_EXPORTER_OTLP_HEADERS: '{{resolve:ssm-secure:/openobserve/otlp-basic-token}}'

    # Identity — this is what you filter on in OpenObserve. Get it right.
    OTEL_SERVICE_NAME: <kebab-case-service-name>
    OTEL_RESOURCE_ATTRIBUTES: 'deployment.environment=dev,service.version=0.1.0,cloud.provider=aws'

    # Lambda is short-lived; do not sit on spans waiting for a batch to fill.
    OTEL_BSP_SCHEDULE_DELAY: '500'

    # Continue traces that arrive from API Gateway (see section 4). Required, not optional.
    OTEL_PROPAGATORS: 'xray,tracecontext,baggage'

    # Sampling. Start at 1.0 while building, then turn it down (see section 7).
    OTEL_TRACES_SAMPLER: parentbased_always_on
```

Note that `{{resolve:ssm-secure:...}}` returns the raw parameter value, not `Authorization=Basic <token>` — store the parameter as just the base64 token and format the full header value in a small wrapper (e.g. a Lambda extension env var transform, or bake the `Authorization=Basic ` prefix into the parameter value itself when you create it, matching how the connectivity check in section 2 uses it). Confirm the exact format matches what's actually stored before relying on it.

The endpoint is the `/api/default` **base** — the SDK appends `/v1/traces`, `/v1/metrics`, and `/v1/logs` itself. Do not include the signal path.

### 3.3 What you get for free

ADOT auto-instrumentation covers the AWS SDK, so **DynamoDB calls produce spans automatically** with the table name, operation, and result. The same applies to any other `boto3` call. You should not need to hand-write spans for AWS calls.

Add manual spans only for business-meaningful units of work:

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def handler(event, context):
    with tracer.start_as_current_span("validate_claim") as span:
        span.set_attribute("claim.id", claim_id)
        span.set_attribute("claim.amount_cents", amount)
        ...
```

Attribute naming: follow the [OTel semantic conventions](https://opentelemetry.io/docs/specs/semconv/) for anything that has one (`http.*`, `db.*`, `aws.*`), and use a consistent prefix of your own for domain attributes. Do not put PII in attributes.

### 3.4 Cold starts

The ADOT layer adds meaningful cold-start latency — expect several hundred milliseconds to around a second on first invocation. Mitigate by keeping the deployment package lean, right-sizing memory (more memory means more CPU, which shortens init), and importing only what you need at module scope. Do not reach for provisioned concurrency as a fix (out of scope for this account's projects — see steering).

---

## 4. API Gateway

API Gateway does **not** emit OpenTelemetry data itself. There is no OTel span for the API Gateway hop, so handle it in two parts.

### 4.1 Access logs

Enable access logging on the stage with a JSON format, then deliver those logs into OpenObserve via the existing pipeline pattern — CloudWatch Logs subscription filter → Amazon Data Firehose → OpenObserve.

Suggested access log format:

```json
{
  "requestId": "$context.requestId",
  "traceId": "$context.xrayTraceId",
  "httpMethod": "$context.httpMethod",
  "path": "$context.path",
  "status": "$context.status",
  "responseLatency": "$context.responseLatency",
  "integrationLatency": "$context.integrationLatency",
  "errorMessage": "$context.error.message"
}
```

Including `$context.xrayTraceId` is what lets you correlate an access log line with the Lambda trace.

### 4.2 Trace continuity — X-Ray propagation is required here

API Gateway propagates `X-Amzn-Trace-Id`, not W3C `traceparent`. This is why `OTEL_PROPAGATORS` includes `xray` in section 3.2 — without it, the Lambda starts a brand-new trace and the link to the incoming request is lost.

**Enable X-Ray tracing (`Tracing: Active`) on the API Gateway stage so the header is populated.** This is a real, required exception to any blanket "no X-Ray" rule: you do not have to actually consume X-Ray as a viewing backend/console for this to matter — its trace-ID header propagation mechanism is what stitches the API Gateway hop to the Lambda trace before OpenObserve ever sees it. Skipping this produces two disconnected traces instead of one continuous one.

---

## 5. Logs

Two options. Pick one per service and be consistent.

**Option A — CloudWatch → Firehose (recommended for this account).** Write structured JSON with AWS Lambda Powertools `Logger` and let the existing pipeline carry it. Nothing extra to build, no additional egress, and it keeps working even if the OTel exporter is misconfigured. Logs land in the `cloudwatch` stream.

```python
from aws_lambda_powertools import Logger

logger = Logger(service="claims-api")

@logger.inject_lambda_context
def handler(event, context):
    logger.info("claim received", extra={"claim_id": claim_id})
```

**Option B — OTLP logs direct.** Verified working. Gives resource attributes on every record and lands logs in the `default` logs stream alongside traces. Costs a dependency on the exporter being correctly configured, and log delivery then shares a failure mode with tracing.

Either way: emit JSON, never bare strings, and include the trace id in log records so you can pivot from a log line to a trace.

---

## 6. Naming and tagging

Consistency matters more than the specific scheme, because these become your filters.

- `OTEL_SERVICE_NAME` — one per deployable unit, kebab-case (e.g. `claims-api`, `claims-worker`). Not one per Lambda function unless the function _is_ the service.
- `deployment.environment` — `dev`, `staging`, `prod`. Always set it; without it you cannot separate environments in a shared instance.
- `service.version` — wire it to the build version so a regression can be correlated with a deployment.

Tag AWS resources per this account's convention, including reaper exemptions:

```python
Tags.of(stack).add("project", "<project-name>")
Tags.of(stack).add("auto-stop", "false")
Tags.of(stack).add("auto-delete", "false")
```

---

## 7. Account-specific constraints

These are properties of the current OpenObserve deployment, not of OpenObserve generally. Several will fail silently if ignored.

| Constraint         | Value           | What happens                                                                                               |
| ------------------ | --------------- | ---------------------------------------------------------------------------------------------------------- |
| **Data retention** | **7 days**      | Data older than this is deleted. Do not build anything that assumes long history.                          |
| Late-arriving data | 24 hours        | Events with a timestamp older than 24h are **rejected**, not backdated. Matters for replays and backfills. |
| Future-dated data  | 24 hours        | Same, in the other direction. Clock skew will drop spans.                                                  |
| Query timeout      | 45s             | Long queries return an OpenObserve error rather than hanging.                                              |
| Ingest path        | CloudFront only | The load balancer rejects anything not from CloudFront.                                                    |
| VPC Lambdas        | Need egress     | Functions running in a VPC need a NAT route to reach CloudFront. Functions outside a VPC are fine.         |

**Sampling.** Start at 100% (`parentbased_always_on`) while building, then reduce. At 7-day retention on a demo-sized cluster, an unsampled chatty service will dominate storage and slow everyone's queries. Use `parentbased_traceidratio` with `OTEL_TRACES_SAMPLER_ARG=0.1` once things are working, and keep errors sampled at 100% if a tail sampler is added later.

**Shared instance.** Other projects use this cluster. Set `service.name` and `deployment.environment` correctly so data stays separable, and never disable or delete other projects' streams.

---

## 8. Definition of done

Before calling instrumentation complete, confirm all of these in the OpenObserve UI:

1. A trace appears with the correct `service.name` and spans back the full request.
2. That trace includes an automatically generated **DynamoDB span** with the table and operation.
3. An API Gateway access log line is queryable and shares a trace id with the Lambda trace.
4. Application logs are queryable and carry the trace id.
5. At least one custom business metric appears under Metrics.
6. An induced error produces a span with a non-OK status and a recorded exception.
7. `deployment.environment` is present on everything, and filtering by it works.

Point 3 is the one most often skipped, and the one that pays off during an incident.

---

## 9. Troubleshooting

Work through these in order:

1. **Re-run the connectivity check in section 2.** If that fails, it is credentials or networking, not application code.
2. **401** — the Basic token is wrong or truncated. It must be base64 of `email:password` with no trailing newline.
3. **404** — the signal path was probably included in `OTEL_EXPORTER_OTLP_ENDPOINT`. It must end at `/api/default`.
4. **200 but nothing visible** — almost always the UI time range. Widen it. Then check the timestamp constraints in section 7; a skewed clock gets records silently rejected.
5. **Traces split into two** — the `xray` propagator is missing from `OTEL_PROPAGATORS`, or `Tracing: Active` is off on the API Gateway stage.
6. **Nothing at all from Lambda** — confirm `AWS_LAMBDA_EXEC_WRAPPER=/opt/otel-instrument` is set and the ADOT layer is actually attached to the published function version.
7. **Enable exporter debug logging** with `OTEL_LOG_LEVEL=debug` and read the CloudWatch logs for the function; the exporter reports HTTP failures there.
