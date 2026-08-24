---
inclusion: always
name: security-policies
description: 'Security policies: Cognito + MFA + passkeys, secrets via SSM Parameter Store SecureString by default (Secrets Manager only when rotation/RDS/service integration requires it), with an explicit opt-in exception for committing plaintext secrets in private solo repos, IAM least privilege, KMS managed keys preferred, encryption at rest + in transit, S3 OAC, input validation, OWASP prevention, dependency security. Use when reviewing or implementing security controls.'
---

# Security Policies

## Authentication

- Amazon Cognito User Pools — MFA is **never forced by default**. Use Cognito's default `Mfa.OFF` unless a developer explicitly asks for MFA to be required or optional; when they do, apply exactly what they specify (`Mfa.OPTIONAL` or `Mfa.REQUIRED`) rather than defaulting to "more secure" on your own initiative. See `aws-standards.md` for the passkey/password baseline this pairs with.
- JWT token validation on every API request
- Token rotation and short expiry (1 hour access, 30 day refresh)
- Programmatic session management in Playwright tests via `storageState` (see `development-quality-gates.md` → "Playwright E2E Standards") — never a UI login flow, and never a Cypress-style `cy.session()` call (this project is Playwright-only)

## Secrets Management

- **Prefer AWS SSM Parameter Store (`SecureString`, KMS-encrypted) for secrets by default.** It is simpler and cheaper for static secrets (third-party API keys, tokens, webhook signing keys) that don't need managed rotation.
- **Use AWS Secrets Manager only when you specifically need it**, for example:
  - **RDS / Aurora / Redshift / DocumentDB credentials** — use the managed master password with native rotation and RDS Proxy integration
  - **An AWS service that requires a Secrets Manager secret ARN** to connect a client (e.g., MSK SASL/SCRAM, Amazon MQ event-source credentials, some Bedrock Knowledge Base vector-store connectors)
  - **Automatic credential rotation** — Secrets Manager has built-in rotation; Parameter Store does not
  - **Cross-account secret sharing**, or values larger than the Parameter Store limit
- **In production and any shared/public repo, never put secrets in plaintext environment variables** — Lambda env vars are visible in the console, `GetFunctionConfiguration`, and CloudFormation. Fetch from SSM `SecureString` or Secrets Manager at runtime and cache outside the handler (e.g., the Lambda Powertools `parameters` utility).
- Encrypt with KMS — prefer AWS managed keys unless a compliance requirement dictates customer-managed (see KMS rule below).
- **In production and any shared/public repo, never hardcode API keys, passwords, or tokens in code.** (For private solo repos, see "Committing Secrets in Private Repos" below — the user may opt into this.)
- Use plain SSM Parameter Store (`String`) for non-secret configuration; environment variables are acceptable for **non-secret** config only.

## Committing Secrets in Private Repos (user opt-in)

The rules above (SSM/Secrets Manager, no plaintext, no hardcoding, gitignore `.env`) are the **default** and remain mandatory for production, shared, team, or public repositories.

**However**, when the user is working in a **private, single-owner repository** — common for demos, prototypes, and throwaway projects — they may deliberately choose to commit API keys, secrets, passwords, and other credentials in plaintext files under version control. This is a legitimate, informed tradeoff for a repo only they can access.

When this applies:

- **Honor it without pushback.** Do NOT repeatedly refuse, warn, or re-litigate the decision once the user has expressed it. Do NOT add `.env`/secret patterns to `.gitignore` against their wishes, and do NOT strip hardcoded values they intentionally placed.
- **A single, brief heads-up is fine the first time** ("noting these are real credentials in a committed file"), but then proceed and don't raise it again in the session.
- **Guardrails that still apply** even here: (a) if the user has not indicated the repo is private/solo, ask once before committing real secrets rather than assuming; (b) never push secrets to a repo you can see is public or has other collaborators; (c) never exfiltrate the secret values anywhere else (logs sent to third parties, external endpoints).
- This exception is about respecting the user's explicit choice for their own private repos — it is not license to scatter secrets carelessly in code destined for production or sharing.

## IAM

- **Least privilege for high-risk areas** — no wildcard (`*`) actions or resources in production for anything touching sensitive data, destructive operations, cross-account access, or privilege escalation surfaces (e.g., a Lambda writing PII, anything with `iam:*`/`s3:Delete*`/admin-adjacent actions). Use condition keys (`aws:SourceArn`, `aws:PrincipalOrgID`), permission boundaries for delegated administration, and separate read/write policies here.
- **Minimize role count for low-risk areas** — for routine, non-sensitive operations (e.g., a handful of Lambdas reading/writing the same DynamoDB table, internal utility functions with no external attack surface), it's fine to reuse a single well-scoped IAM role across them rather than minting a new role per function. The goal is not zero roles or a role-per-resource maximalism — it's the fewest roles that still keep high-risk permissions isolated.
- Judgment call, not a hard threshold: when unsure whether something is high-risk, treat it as high-risk and isolate it.
- No inline policies — use managed policies only, regardless of risk tier.

## Data Protection

- **Encryption at rest is always on — no exceptions.** For every resource, prefer the **AWS-owned key** (no KMS involvement, no cost, no key policy to manage) when the service offers one as its default. **DynamoDB always uses its AWS-owned default** — never switch it to an AWS-managed or customer-managed KMS key. See `aws-standards.md` "DynamoDB Encryption".
- For services where an AWS-owned key isn't an option (e.g., S3, SQS, SNS, EBS default to no encryption or require you to opt into a KMS key), use an **AWS-managed KMS key** (`aws/service-name`) as the next-best default — not customer-managed.
- **Customer-managed KMS keys are the last resort** — use them only when a specific compliance requirement mandates control over key rotation or cross-account access. Don't reach for one "to be safe"; it adds cost, complexity, and IAM/key-policy surface area with no security benefit over AWS-managed for most workloads.
- So the order of preference, every time: AWS-owned (if available) → AWS-managed KMS → customer-managed KMS (only if compliance requires it).
- Encryption in transit: TLS everywhere, ACM certificates.
- S3: Block all public access, use CloudFront with OAC for public content.
- DynamoDB: Enable point-in-time recovery.

## Input Validation

- Validate at API Gateway (request models) AND Lambda (defense in depth)
- Sanitize all user input before storage or display
- Use zod schemas for TypeScript, pydantic for Python
- Reject unexpected fields, enforce type constraints

## Logging & Audit

- **NEVER create a new AWS CloudTrail trail in any project.** The organization already provisions an org-wide CloudTrail by default (org-level trail applied via AWS Organizations) — every account, including this one, is already covered. Do NOT add `aws_cloudtrail.Trail` (CDK), `AWS::CloudTrail::Trail` (CloudFormation), or any `aws cloudtrail create-trail` call to a project's infrastructure code. If a project appears to need trail-level configuration (e.g., a specific S3 bucket for logs, event selectors, CloudWatch Logs integration), treat that as a signal to check with the user/org security team rather than provisioning a new trail — assume API activity is already logged org-wide.
- **VPC Flow Logs are OFF by default — never enable them unless the user explicitly asks.** They add cost (data ingestion + storage) and noise; don't provision them speculatively "for visibility."
- **S3 access logging is OFF by default — never enable it unless the user explicitly asks.** Same reasoning: real cost and storage overhead for logs most demo/prototype projects never look at. Enable it per-bucket only when requested, not as a blanket default for "sensitive buckets."
- Lambda Powertools structured JSON logging with correlation IDs
- Never log sensitive data (PII, tokens, passwords)
- By default, add `.env`, `.env.local`, `*.secret` to `.gitignore` and do not commit secrets to version control. **Exception — private solo repos (see "Committing Secrets in Private Repos" below):** when the user confirms the repo is private and single-owner (typical for demos/prototypes), honor their choice to commit keys/secrets/passwords in plaintext without pushback.

## OWASP Prevention

- XSS: Sanitize output, use React's built-in escaping
- CSRF: Use SameSite cookies, anti-CSRF tokens
- Injection: Parameterized queries, never string concatenation for SQL/DynamoDB
- Broken auth: Rate limit login attempts, account lockout after failures

## Dependency Security

- Run `npm audit` and `pip audit` before every deployment
- Zero critical or high vulnerabilities allowed — fix or replace the dependency
- Use Dependabot or Renovate for automated dependency updates
- Review all new dependencies before adding — prefer well-maintained packages with >1000 weekly downloads
