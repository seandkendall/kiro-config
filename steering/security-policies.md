---
inclusion: always
name: security-policies
description: "Security policies: Cognito + MFA + passkeys, secrets via SSM Parameter Store SecureString by default (Secrets Manager only when rotation/RDS/service integration requires it, never plaintext env vars), IAM least privilege, KMS managed keys preferred, encryption at rest + in transit, S3 OAC, input validation, OWASP prevention, dependency security. Use when reviewing or implementing security controls."
---

# Security Policies

## Authentication

- Amazon Cognito User Pools with MFA enabled
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
- **Never put secrets in plaintext environment variables** — Lambda env vars are visible in the console, `GetFunctionConfiguration`, and CloudFormation. Fetch from SSM `SecureString` or Secrets Manager at runtime and cache outside the handler (e.g., the Lambda Powertools `parameters` utility).
- Encrypt with KMS — prefer AWS managed keys unless a compliance requirement dictates customer-managed (see KMS rule below).
- Never hardcode API keys, passwords, or tokens in code.
- Use plain SSM Parameter Store (`String`) for non-secret configuration; environment variables are acceptable for **non-secret** config only.

## IAM

- Least privilege — no wildcard (`*`) actions or resources in production
- Separate read/write policies
- Use condition keys (aws:SourceArn, aws:PrincipalOrgID) to restrict scope
- Permission boundaries for delegated administration
- No inline policies — use managed policies only

## Data Protection

- Encryption at rest: KMS for DynamoDB, S3, SQS, SNS, EBS
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

- CloudTrail enabled for all API activity
- VPC Flow Logs for network monitoring
- S3 access logging for sensitive buckets
- Lambda Powertools structured JSON logging with correlation IDs
- Never log sensitive data (PII, tokens, passwords)
- Add `.env`, `.env.local`, `*.secret` to `.gitignore` — never commit secrets to version control

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
