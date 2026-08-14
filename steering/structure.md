---
inclusion: auto
name: structure
description: 'Directory and file organization conventions: cdk-backend/lambda/functions/, cdk-backend/cdk/, frontend/src/components/, tests/e2e/, .kiro/steering/. Naming: kebab-case dirs, PascalCase React components, snake_case Python files. Use when scaffolding new files or projects.'
---

# Project Structure

## Directory Layout

```
/
├── cdk-backend/
│   ├── lambda/functions/
│   └── cdk/
├── frontend/
│   ├── src/
│   └── public/
├── tests/
│   ├── e2e/
│   │   ├── pages/
│   │   ├── fixtures/
│   │   └── *.spec.ts
├── tests/
│   └── integration/
├── deploy.sh
└── .kiro/steering/
```

## File Organization

- Lambda functions: `cdk-backend/lambda/functions/function_name/function_name.py`
- CDK stacks: `cdk-backend/cdk/`
- React components: `frontend/src/components/`
- Playwright E2E tests: `tests/e2e/*.spec.ts`
- Playwright Page Objects: `tests/e2e/pages/*.ts`
- Steering docs: `.kiro/steering/`

## Naming Conventions

- Use kebab-case for directories
- Use PascalCase for React components
- Use snake_case for Python files
- Use descriptive, project-specific stack names

## Import Patterns

- Prefer absolute imports in React
- Use relative imports for local modules
- Group imports: external, internal, relative
