---
name: reinvent-stack-toolkit
description: Technical patterns and known-only-by-live-invocation pitfalls for the reinvent agent's fixed stack. Covers how to wire services correctly; says nothing about what to build. Read this BEFORE writing any code for a new project on this stack. Only fall back to live AWS docs search when a value here looks stale or the project needs something this skill doesn't cover.
verified: 2026-09-30
---

# reinvent Stack Toolkit

**Trust policy:** every ARN, model ID, and pattern below was verified against this
account's real infrastructure as of the `verified` date above. Treat them as correct
without re-querying live AWS for roughly 90 days from that date. **Only re-verify a
specific value live if it actually fails at build or deploy time** (a stale ARN, a
rejected model ID, a changed API shape). If something here turns out stale, fix it here
and bump the date, so the next build doesn't re-pay the same research cost.

**Observability is not covered here.** The build prompt specifies it per project.

## Verified ARNs & versions (quick reference)

Pinned values confirmed against live AWS docs/account state as of the `verified` date
above. Use these directly without re-querying; only re-verify if one fails at build or
deploy time, per the trust policy.

| Value | Pinned | Scope / caveat |
|---|---|---|
| ADOT Lambda layer for Python | `arn:aws:lambda:<region>:901920570463:layer:aws-otel-python-<arch>-ver-1-32-0:7` (`<arch>` = `amd64` or `arm64`) | **Python 3.8-3.13 only.** This stack's Lambdas run `python3.14` -- the layer is NOT compatible, confirmed by live failure (`No module named 'aws_xray_sdk'` at cold start). Keep this ARN on file for the day this stack's Python version drops to 3.13 or earlier, or for a sibling project pinned to an older runtime. For `python3.14` today, skip ADOT entirely -- see `references/pitfalls.md` item 4 for the Powertools+`aws-xray-sdk` alternative this stack actually uses. |
| `amazon.nova-lite-v1:0` | bare model ID (no inference profile needed) | Confirmed invokable on-demand directly via Converse in this account/region (us-east-1) as of 2026-07-14. **Correction:** `amazon.nova-lite-v2:0` does not exist in this account/region and fails Converse with `ValidationException: The provided model identifier is invalid.` The newer `amazon.nova-2-lite-v1:0` exists but is `INFERENCE_PROFILE`-only (needs `us.amazon.nova-2-lite-v1:0` or `global.amazon.nova-2-lite-v1:0`) -- `amazon.nova-lite-v1:0` is the correct bare on-demand ID. If a `ValidationException` about invalid model identifier appears again, re-run `aws bedrock list-foundation-models --query "modelSummaries[?contains(modelId,'nova')].modelId"` before trusting any pinned Nova ID here. |

## What's here

1. `references/pitfalls.md` -- read this in full before the first deploy, not after the
   first failure. Every entry passed static validation and a clean deploy on a prior
   build and only broke on real invocation.
2. Technical pattern files:
   - `references/bedrock-structured-extraction-pattern.py` -- Converse with forced
     tool-use for structured output from an image, document, or text input
3. `references/frontend-toolkit-notes.md` -- Vite + Tailwind v4 + shadcn/ui setup
   gotchas (including the stray-`@`-directory bug on `shadcn init`) and the
   icon-generation snippet.

## The pitfalls that cost the most time historically

Full detail and fixes in `references/pitfalls.md` -- this is just the index:

1. `sam sync --code` can desync a function's separately-managed dependency layer
   without any error. Never use it mid-build; always redeploy with the full
   `sam deploy --express` path.
3. Bedrock Converse: a specific model may (a) require an inference profile ID instead
   of the bare model ID, and (b) reject `inferenceConfig` fields like `temperature` as
   deprecated for that model generation. Both fail only on real invocation, never on
   deploy. Omit `inferenceConfig` unless a field is confirmed supported.

## Relationship to the shared skills

This skill is attached only to the `reinvent` agent. `aws-serverless-patterns.md` is
also attached and remains the authority for general Lambda/API Gateway/DynamoDB/
EventBridge patterns shared with the CDK-based agents (DynamoDB `Decimal` requirement,
`wait_for_callback` raw-string parsing, EventBridge envelope unwrapping and the Lambda
permission a rule target needs).
