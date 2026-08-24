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
- Programmatic session management with `cy.session()` in tests

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

- Least privilege — no wildcard (`*`) actions or resources in production
- Separate read/write policies
- Use condition keys (aws:SourceArn, aws:PrincipalOrgID) to restrict scope
- Permission boundaries for delegated administration
- No inline policies — use managed policies only

## Data Protection

- Encryption at rest: KMS for S3, SQS, SNS, EBS. **DynamoDB is the exception — always use its default encryption (AWS owned key), never KMS.** See `aws-standards.md` "DynamoDB Encryption".
- Encryption in transit: TLS everywhere, ACM certificates
- **ALWAYS use AWS managed KMS keys** (`aws/service-name`) over customer-managed keys unless there is a specific compliance requirement for key rotation control or cross-account access. Managed keys are simpler, cheaper, and sufficient for most workloads.
- S3: Block all public access, use CloudFront with OAC for public content
- DynamoDB: Enable point-in-time recovery

## Input Validation

- Validate at API Gateway (request models) AND Lambda (defense in depth)
- Sanitize all user input before storage or display
- Use zod schemas for TypeScript, pydantic for Python
- Reject unexpected fields, enforce type constraints

## Logging & Audit

- **NEVER create a new AWS CloudTrail trail in any project.** The organization already provisions an org-wide CloudTrail by default (org-level trail applied via AWS Organizations) — every account, including this one, is already covered. Do NOT add `aws_cloudtrail.Trail` (CDK), `AWS::CloudTrail::Trail` (CloudFormation), or any `aws cloudtrail create-trail` call to a project's infrastructure code. If a project appears to need trail-level configuration (e.g., a specific S3 bucket for logs, event selectors, CloudWatch Logs integration), treat that as a signal to check with the user/org security team rather than provisioning a new trail — assume API activity is already logged org-wide.
- VPC Flow Logs for network monitoring
- S3 access logging for sensitive buckets
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
