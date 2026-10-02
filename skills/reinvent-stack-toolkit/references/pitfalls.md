# Pitfalls found only by real invocation

Every entry below passed `sam validate --lint`, a clean `sam build`, and a successful
`sam deploy` on a prior project. None of them are visible statically. Read this whole
file before the first deploy of a new project on this stack -- that is strictly cheaper
than rediscovering any one of these live.

Ordered roughly by how much time each one costs when rediscovered from scratch.

---


## 1. `sam sync --code` can silently desync a function's dependency layer

`sam sync --code` updates the function's code directly via the Lambda API, bypassing
CloudFormation. For simple functions this is a fast, safe iteration loop. For a function
whose dependencies SAM manages as a separate auto-generated Lambda layer (which happens
for large dependency sets),
`sam sync --code` can update the function's code layer while failing to publish a new
version of the dependency layer, with only a warning easy to miss:

```
Cannot find any versions for layer <stack>-<Function><hash>-DepLayer. Try sam sync without --code or sam deploy.
```

**Symptom:** The function's code hash changes, but a runtime dependency that should
have been updated (or removed) alongside it is still the old version -- silent drift
between what you think you deployed and what's actually running.

**Fix:** Do not use `sam sync --code` as a mid-demo shortcut on this stack. Always
redeploy with the full path: `sam build` then `sam deploy --express`. It's still fast
(Express mode), and it's the only path guaranteed to keep code and dependency layers
consistent.

---

## 2. Bedrock Converse: inference profile requirement and deprecated inferenceConfig fields

Two separate, independent failure modes, both invisible until a real Converse call:

**2a. Bare model ID rejected for on-demand invocation.**

```
ValidationException: Invocation of model ID <model-id> with on-demand throughput
isn't supported. Retry your request with the ID or ARN of an inference profile
that contains this model.
```

Check first, before writing any Bedrock code:

```bash
aws bedrock list-inference-profiles --region <region> \
  --query "inferenceProfileSummaries[?contains(inferenceProfileId,'<model-name-fragment>')]"
```

Use the matching `us.<model-id>` (regional) or `global.<model-id>` inference profile ID
as the `modelId` parameter to `Converse`/`ConverseStream` -- it is the correct
invocation identifier for the same model, not a different model. IAM must then grant
`bedrock:InvokeModel`/`InvokeModelWithResponseStream` on **both** the inference-profile
ARN and every underlying foundation-model ARN it can route to:

```bash
aws bedrock get-inference-profile --inference-profile-identifier us.<model-id> \
  --query 'models[].modelArn'
```

A cross-region profile routes to multiple regions -- each region's foundation-model ARN
needs its own line in the IAM policy `Resource:` list.

**2b. A specific inferenceConfig field rejected as deprecated for that model generation.**

```
ValidationException: The model returned the following errors: `temperature` is
deprecated for this model.
```

Different model families and generations accept different subsets of
`inferenceConfig` fields (`temperature`, `topP`, `maxTokens`, etc.) -- there is no
universal set that's safe to always include. **Omit `inferenceConfig` entirely unless a
specific field is confirmed supported for the exact model in use.** If a demo genuinely
needs deterministic output, confirm the field is accepted for that specific model before
adding it back, and remove it rather than assuming the whole call shape is broken if it
errors.

---

## 3. Forced tool-use is the reliable pattern for structured extraction

Not a failure mode, but the pattern that avoids one: when a Converse call needs to
return structured data (extracted fields from an image, a parsed form, a classification
result), don't parse free-text model output. Define a tool whose input schema is the
exact structure needed, and force the model to call it with `toolChoice`:

```python
toolConfig={
    "tools": [tool_spec],
    "toolChoice": {"tool": {"name": tool_name}},
}
```

The response's `output.message.content` will contain a `toolUse` block with `input`
matching the schema, every time, with no free-text parsing or JSON-extraction-from-prose
step needed. See `references/bedrock-structured-extraction-pattern.py` for the full
working example (image + document input, confidence-scored extraction).

---

## 4. ADOT Python Lambda layer does not support Python 3.14

The managed ADOT Python layer ARN is pinned and correct as of the `verified` date in
`SKILL.md`'s "Verified ARNs & versions" table:

```
arn:aws:lambda:<region>:901920570463:layer:aws-otel-python-<arch>-ver-1-32-0:7
```

The ARN itself isn't the problem -- it only lists support through Python 3.13, and is
**not compatible with the `python3.14` runtime** this agent's stack mandates. Using it
on 3.14 produces a cold-start-only failure, invisible to `sam validate --lint` and
`sam build`:

```
Unable to import module 'otel_wrapper': No module named 'aws_xray_sdk'
```

**Fix -- skip ADOT entirely for this stack's observability.** Go straight to AWS Lambda
Powertools' `Tracer`/`Logger`/`Metrics` (already the mandated observability library) plus an
explicit `aws-xray-sdk` pin in each function's `requirements.txt`:

```
aws-lambda-powertools==3.4.0
aws-xray-sdk==2.14.0
```

Keep `Tracing: Active` on the function (SAM auto-attaches the X-Ray write policy) and
`TracingEnabled: true` on the API stage. No `AWS_LAMBDA_EXEC_WRAPPER`, no ADOT layer ARN,
no collector config needed -- Powertools' `@tracer.capture_lambda_handler` /
`@tracer.capture_method` decorators handle segment/subsegment creation directly against
`aws_xray_sdk`. This is strictly less setup than the ADOT path and avoids the
Python-version compatibility question entirely.

Side effect to plan for: `aws-xray-sdk` pulls in `botocore` as a transitive dependency
(it patches boto3/botocore clients for tracing), which adds roughly 25MB to each
function's zipped package. This is normal and expected -- do not strip bundled
botocore/boto3 to shrink it; AWS's own guidance is to bundle the SDK rather than rely on
the runtime-provided version, and removing it risks a version mismatch with
`aws_xray_sdk`'s internals. If upload time for ~25-30MB packages becomes the bottleneck,
the fix is the network path (see pitfall 6), not the package contents.

---

## 5. DynamoDB rejects Python floats (cross-reference)

Already documented in the shared `aws-serverless-patterns.md` skill's "Known Gotchas"
section -- repeated here only as a pointer since it comes up on nearly every project
that stores a Bedrock-extracted numeric value (a price, a total, a confidence score)
directly: convert every float to `decimal.Decimal(str(value))` before any
`put_item`/`update_item` call. See that skill for the full explanation.

---

## 6. A pre-flight upload-throughput check is cheaper than discovering a stuck deploy 20 minutes in

`sam deploy --express` gives almost no feedback once it starts uploading function
packages -- a stalled multipart upload (common on a corporate VPN with reduced-MTU
tunnel interfaces, or any environment with real packet loss) looks identical in the
CLI's output to a slow-but-progressing one: both just show no new lines for minutes at
a stretch. Diagnosing this after the fact (checking `nettop` retransmit counts,
`list-multipart-uploads`, `list-parts`) costs far more time than checking first.

**Before the first `sam deploy` of a session, run a 10-second upload sanity check:**

```bash
dd if=/dev/urandom of=/tmp/nettest.bin bs=1m count=2 2>/dev/null
curl -s -o /dev/null -w "%{speed_upload} B/s\n" --max-time 15 --data-binary @/tmp/nettest.bin https://httpbin.org/post
rm -f /tmp/nettest.bin
```

If this reports well under ~1 MB/s, stop and flag it to the user before attempting a
real deploy -- do not let `sam deploy` retry silently for tens of minutes. A common
cause worth checking directly: multiple simultaneous VPN clients (e.g. a corporate
OpenVPN agent and Cisco AnyConnect both active), which stack `utun` interfaces at
reduced MTUs (`ifconfig | grep -A1 utun`) and can mangle large uploads specifically
while leaving ICMP ping and small requests unaffected. This is an environment problem,
not a template or code problem -- do not try to work around it by shrinking the deploy
package or retrying with tuned multipart settings; those don't fix a severed/throttled
TCP path and only burn more time confirming what the pre-flight check would have shown
in 10 seconds.