---
inclusion: always
name: tech
description: 'Technology stack: React 19+/TypeScript strict + Tailwind + shadcn/ui + Vite, React Router v8, Python 3.14 Lambda + CDK Python, DynamoDB, API Gateway, AppSync, Cognito, CloudFront, S3, Kiro CLI 2.19.0+ tooling. Use as the canonical reference for which libraries, services, and versions to use.'
---

# Technology Stack

## Frontend

- React 19+ with TypeScript
- Tailwind CSS for styling
- shadcn/ui component library (prefer over custom implementations for: Button, Dialog, AlertDialog, DropdownMenu, Form, Input, Select, Table, Tabs, Toast, Tooltip)
- Vite for build tooling

## Frontend Patterns

- TypeScript strict mode enabled — no `any` types, no implicit any
- State: React Query / TanStack Query for server state, Zustand for client state
- Forms: react-hook-form + zod validation
- Routing: **React Router v8** (mandatory — v8.0.0 shipped June 2026, ESM-only builds, default middleware, Node 22.22+ required). Lazy-loaded routes. If an existing project is on an older major (v6/v7), upgrade it to v8 during the next daily-maintenance pass unless there's a documented, specific reason it can't be upgraded yet (e.g., a blocking incompatible dependency) — note that reason in the project's own docs if you hit one, don't just silently stay behind.
- No prop drilling — use Context or Zustand for shared state
- Every web app MUST include a favicon and app icons for all device types (Apple Touch Icon 180x180, Android Chrome 192x192 + 512x512, favicon.ico 32x32). Generate these using the image-gen subagent or Bedrock Image if not provided.

## Responsive Breakpoints

Four tiers, covering phones through TV/dashboard displays. Use consistently across every project — this exact set is referenced from `accessibility-standards.md` and `skills/react-frontend-patterns.md` too; keep all three in sync if you ever change it.

- **Mobile** (phones — iPhone, Android): 375px, default/mobile-first, no prefix
- **Tablet / small laptop**: `md:` (768px)
- **Desktop / widescreen laptop & monitor**: `lg:` (1280px)
- **TV / dashboard** (large-format displays, kiosk screens, car dashboards, living-room TVs): `2xl:` (1920px) — design for viewing distance: larger text, higher contrast, simplified navigation (often no pointer/keyboard, just remote/voice/touch)
- All pages must be tested at all four breakpoints

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
- Testing: pytest + moto (Python), Vitest + React Testing Library (React), Playwright (E2E with data-testid selectors)
- `awsdac` (CLI) for generating PNG architecture diagrams with official AWS icons (`brew install awsdac`)

## Kiro CLI Tooling

- Kiro CLI tooling — check `settings/cli.json` → `chat.defaultModel` for the current default model (don't hardcode a model name here; it drifts). Run `kiro-cli chat --list-models` to see the current default and full model list.
- **Model reasoning effort** — tune depth with `/effort` (low / medium / high / xhigh / max), or set it at launch with `kiro-cli chat --effort <level>`. Lower effort = faster/cheaper for simple tasks; higher = more reasoning for complex work.
- **Model + effort preferences persist automatically** (CLI 2.6.0+) — once you pick a `/model` or `/effort`, it carries into future sessions; no `set-current-as-default` step needed.
- Master agent (`ctrl+1`) is the entry point — delegates to specialist subagents via `subagent` tool
- Use `subagent` for synchronous orchestration; `delegate` only for long-running async background tasks
- `deploy.sh` scripts route verbose output via `$AGENT_DISPLAY_OUT` and structured summaries via `$AGENT_CONTEXT_OUT` so the agent context stays lean
- AWS MCP Server (`mcp-proxy-for-aws`) is the single AWS interaction point — no per-service awslabs MCP servers
