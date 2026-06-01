---
inclusion: always
name: tech
description: Technology stack: React 18+/TypeScript strict + Tailwind + shadcn/ui + Vite, Python 3.14 Lambda + CDK Python, DynamoDB, API Gateway, AppSync, Cognito, CloudFront, S3, Kiro CLI 2.3.0+ tooling. Use as the canonical reference for which libraries, services, and versions to use.
---

# Technology Stack

## Frontend

- React 18+ with TypeScript
- Tailwind CSS for styling
- shadcn/ui component library (prefer over custom implementations for: Button, Dialog, AlertDialog, DropdownMenu, Form, Input, Select, Table, Tabs, Toast, Tooltip)
- Vite for build tooling

## Frontend Patterns

- TypeScript strict mode enabled — no `any` types, no implicit any
- State: React Query / TanStack Query for server state, Zustand for client state
- Forms: react-hook-form + zod validation
- Routing: React Router v6+ with lazy-loaded routes
- No prop drilling — use Context or Zustand for shared state
- Every web app MUST include a favicon and app icons for all device types (Apple Touch Icon 180x180, Android Chrome 192x192 + 512x512, favicon.ico 32x32). Generate these using the image-gen subagent or Bedrock Image if not provided.

## Responsive Breakpoints

- Mobile: 375px
- Tablet: 768px
- Desktop: 1280px
- All pages must be tested at all three breakpoints

## Backend

- AWS Lambda with Python 3.14
- AWS CDK for infrastructure (Python only — never TypeScript for CDK)
- DynamoDB for data storage
- API Gateway for REST APIs
- AppSync for GraphQL APIs

## Authentication

- Amazon Cognito User Pools
- JWT token validation

## Deployment

- AWS CloudFormation via CDK
- CloudFront for content delivery
- S3 for static assets

## Development Tools

- AWS Lambda Powertools for observability
- cdk-nag for security validation
- ESLint and Prettier for code quality
- Testing: pytest + moto (Python), Vitest + React Testing Library (React), Cypress (E2E)
- `awsdac` (CLI) for generating PNG architecture diagrams with official AWS icons (`brew install awsdac`)

## Kiro CLI Tooling

- Kiro CLI 2.3.0+ with Claude Opus 4.8 (adaptive thinking) as default model
- Master agent (`ctrl+1`) is the entry point — delegates to specialist subagents via `subagent` tool
- Use `subagent` for synchronous orchestration; `delegate` only for long-running async background tasks
- `deploy.sh` scripts route verbose output via `$AGENT_DISPLAY_OUT` and structured summaries via `$AGENT_CONTEXT_OUT` so the agent context stays lean
- AWS MCP Server (`mcp-proxy-for-aws`) is the single AWS interaction point — no per-service awslabs MCP servers
