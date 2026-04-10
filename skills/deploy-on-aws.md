---
inclusion: auto
name: deploy-on-aws
description: "Deploy applications to AWS. Triggers on phrases like: deploy to AWS, host on AWS, run this on AWS, AWS architecture, estimate AWS cost, generate infrastructure. Analyzes any codebase and deploys to optimal AWS services."
---

# Deploy on AWS

Take any application and deploy it to AWS with minimal user decisions.

## Philosophy

**Minimize cognitive burden.** User has code, wants it on AWS. Pick the most straightforward services. Don't ask questions with obvious answers.

## Workflow

1. **Analyze** - Scan codebase for framework, database, dependencies
2. **Recommend** - Select AWS services, concisely explain rationale
3. **Estimate** - Show monthly cost before proceeding
4. **Generate** - Write IaC code with security defaults applied
5. **Deploy** - Run security checks, then execute with user confirmation

## Defaults

Default to **dev-sized** (cost-conscious: small instance sizes, minimal redundancy, single-AZ) unless user says "production-ready".

## MCP Servers

### awsknowledge
Consult for architecture decisions. Use when choosing between AWS services or validating that a service fits the use case. Helps answer "what's the right AWS service for X?"

### awspricing
Get cost estimates. **Always present costs before generating IaC** so user can adjust before committing.

### awsiac
Consult for IaC best practices. Use when writing CDK/CloudFormation to ensure patterns follow AWS recommendations.

## Principles

- Concisely explain why each service was chosen
- Always show cost estimate before generating code
- Apply security defaults automatically (encryption, private subnets, least privilege)
- Run IaC security scans (cdk-nag, cfn-nag) before deployment
- Don't ask "Lambda or Fargate?" - just pick the obvious one
- If genuinely ambiguous, then ask
