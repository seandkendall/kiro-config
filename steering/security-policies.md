---
inclusion: always
name: security-policies
description: Security policies: Cognito + MFA + passkeys, Secrets Manager (never env vars), IAM least privilege, KMS managed keys preferred, encryption at rest + in transit, S3 OAC, input validation, OWASP prevention, dependency security. Use when reviewing or implementing security controls.
---

# Security Policies

## Authentication

- Amazon Cognito User Pools with MFA enabled
- JWT token validation on every API request
- Token rotation and short expiry (1 hour access, 30 day refresh)
- Programmatic session management with `cy.session()` in tests

## Secrets Management

- Use AWS Secrets Manager for all secrets — never environment variables
- Enable automatic rotation where supported
- Never hardcode API keys, passwords, or tokens in code
- Use SSM Parameter Store for non-secret configuration

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
