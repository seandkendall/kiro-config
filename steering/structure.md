---
inclusion: always
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
├── cypress/
│   ├── e2e/
│   ├── pages/
│   ├── support/
│   └── fixtures/
├── tests/
│   └── integration/
├── deploy.sh
└── .kiro/steering/
```

## File Organization
- Lambda functions: `cdk-backend/lambda/functions/function_name/function_name.py`
- CDK stacks: `cdk-backend/cdk/`
- React components: `frontend/src/components/`
- Cypress E2E tests: `cypress/e2e/*.cy.ts`
- Cypress Page Objects: `cypress/pages/*.ts`
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
