---
inclusion: always
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

- AWS Lambda with Python 3.13
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
