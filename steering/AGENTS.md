---
inclusion: always
---

# AGENTS.md

## Agent Ecosystem Overview

This workspace uses a multi-agent architecture with a master orchestrator and specialized subagents.

## When to Use Which Agent

- **`/agent master`** (ctrl+1) — Default. Routes to the right specialist.
- **`/agent accounting`** (ctrl+3) — Canadian accounting SaaS (Wave/QuickBooks alternative, Alberta-focused)
- **`/agent serverless`** (ctrl+4) — AWS Lambda, API Gateway, DynamoDB, Powertools, X-Ray
- **`/agent frontend`** (ctrl+5) — React, TypeScript, Tailwind CSS, shadcn/ui components
- **`/agent testing`** (ctrl+6) — pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent
- **`/agent research`** — Deep research on any topic with web search and docs

## Available Subagents

Builder agents automatically delegate to these specialists:

| Subagent | Specialty |
|---|---|
| `serverless` | Lambda, API GW, DynamoDB, Step Functions, Powertools, X-Ray |
| `frontend` | React, TypeScript, Tailwind, shadcn/ui, accessibility |
| `testing` | pytest, Jest/Vitest, delegates Cypress E2E to cypress subagent |
| `cypress` | Cypress E2E tests, Page Objects, 100% coverage target |
| `architect` | Architecture diagrams, cost estimation, Well-Architected reviews |
| `ai-builder` | Bedrock, Strands Agents, prompt engineering, RAG |
| `devops` | CloudWatch monitoring, alerting, cost optimization, incident response |
| `data` | DynamoDB single-table design, Postgres, data modeling |
| `security` | IAM, encryption, cdk-nag, CloudTrail, Well-Architected Security |
| `docs` | READMEs, API docs, ADRs, auto-generated code docs |
| `image-gen` | Image generation via Bedrock Image — Nova Canvas + SD 3.5 |
| `research` | Web search, AWS docs, GitHub, library docs |
| `sap-abap` | SAP ABAP — Clean ABAP, ALV, BAPIs, data migration, CDS, RAP |

## Delegation Rules

- Up to 4 subagents can run in parallel
- Subagents cannot communicate with each other — only report back to the parent
- Use @path syntax to reference files inline — saves tool calls and tokens
