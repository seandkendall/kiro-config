---
inclusion: always
---

# Development Workflow

## Package Management

- Upgrade all packages to latest versions before starting work
- Keep AWS CLI, CDK CLI, Q CLI updated
- Use latest Python and pip versions
- Always use the latest versions of ALL libraries (npm, pip, etc.) — never pin to old versions unless there's a documented compatibility issue

## Daily Maintenance (MANDATORY — at least once per day)

When working on any project across multiple sessions, perform this maintenance at least once per day:

1. **Upgrade all dependencies** across the entire project to their latest versions
   - For each upgraded library, research all changes between the old and new version
   - Apply any required code changes due to API changes, renamed methods, or removed features
   - Verify no deprecated usage remains after the upgrade
2. **Lint all source files** — fix all errors, warnings, and deprecation notices (zero tolerance)
3. **Remove dead code** — unused imports, unreachable code, commented-out blocks
4. **Update README.md** — ensure documentation reflects the current state of the project (dependencies, setup steps, architecture changes)
5. **Build/compile verification** — confirm the project builds cleanly with zero warnings

## Code Quality

**Shell Scripts**:

- Make testable without human intervention (use `-y` flags)
- No interactive prompts in automation scripts

**Python Code** - Fix these issues automatically:

- Unused imports
- Catching general `Exception`
- Direct library imports
- Import ordering
- Lazy % formatting in logging
- Log injection (CWE-117, 93)
- Naive datetime objects

**Build Quality**:

- Fix ALL eslint errors/warnings before deploy
- Run build commands once and check exit codes
- Delete temporary Python files after execution
- `cdk synth`, `npm run build`, and `python -m py_compile` must complete with ZERO errors, ZERO warnings, and ZERO deprecation notices
- If any deprecation warnings appear, upgrade the offending library or fix the usage before proceeding
- All code MUST be successfully compiled or built before considering it complete and ready for testing

## Pre-Deployment Quality Gate

Before every significant deployment, ALL of the following must pass:

1. **Lint**: `npm run lint` (zero errors/warnings) + `pylint`/`flake8` (zero errors)
2. **Build**: `npm run build` with zero warnings, `cdk synth` with zero warnings
3. **Unit tests**: `pytest --cov --cov-fail-under=90` + `npx vitest --coverage`
4. **Cypress E2E**: `npx cypress run` — target 100% coverage via `@cypress/code-coverage`
5. **No deprecations**: All build/synth/test output must be free of deprecation notices
6. **Dependency audit**: `npm audit` and `pip audit` with zero critical/high vulnerabilities

Do NOT deploy if any step fails. Fix first, then deploy.

## Validation

```bash
# Check Python code
pylint your_file.py
flake8 your_file.py

# Check JavaScript/TypeScript
npm run lint
```

## Testing Standards

**Lambda Functions** - Unit tests with pytest:

```python
import pytest
from moto import mock_dynamodb
from your_function import lambda_handler

@mock_dynamodb
def test_lambda_handler():
    # Test implementation
    pass
```

**API Endpoints** - Integration tests:

```python
def test_api_endpoint():
    response = requests.post(api_url, json=test_data)
    assert response.status_code == 200
    assert response.json()["status"] == "success"
```

**React Components** - Component tests with Jest/Vitest:

```typescript
import { render, screen } from '@testing-library/react'
import { Button } from './Button'

test('renders button with text', () => {
  render(<Button>Click me</Button>)
  expect(screen.getByText('Click me')).toBeInTheDocument()
})
```

**Test Organization**:

- Lambda tests: `cdk-backend/lambda/functions/function_name/test_function_name.py`
- React tests: `frontend/src/components/__tests__/Component.test.tsx`
- Integration tests: `tests/integration/`
- Cypress E2E tests: `cypress/e2e/*.cy.ts`
- Cypress Page Objects: `cypress/pages/*.ts`

## Cypress E2E Standards

**Cypress is mandatory for all E2E testing.**

**Selectors**: Always use `data-cy` attributes — never class, id, or tag
**Isolation**: Each test runs independently. Use `beforeEach`, never `afterEach` for cleanup.
**Auth**: Programmatic login via `cy.request()` + `cy.session()` — never UI login
**Waiting**: Never `cy.wait(number)`. Use `cy.intercept()` + `cy.wait('@alias')`.
**Config**: Set `baseUrl` in cypress.config.ts. Use `cy.env()` for secrets.
**Coverage**: Target 100%. Use `@cypress/code-coverage` plugin.

## Documentation Requirements

- Every project MUST have a README.md with: purpose, prerequisites, setup, deployment, architecture overview
- Every Lambda function MUST have a docstring explaining its trigger, input, output, and side effects
- Every React component MUST have a JSDoc comment describing its props and usage
- Every API endpoint MUST be documented in an OpenAPI spec or GraphQL schema with descriptions

## Code Review Checklist

Before considering any feature complete, verify:

- [ ] All new components have `data-cy` attributes for Cypress selectors
- [ ] All new API endpoints are documented in the OpenAPI spec
- [ ] All new Lambda functions use Powertools (Logger, Tracer, Metrics)
- [ ] All new DynamoDB operations use parameterized queries (no string concatenation)
- [ ] No hardcoded values — all config via env vars or SSM
- [ ] No `console.log` in production code — use structured logging
- [ ] Accessibility: keyboard navigable, proper ARIA, color contrast passes

## Kiro Interaction Rules

**Kiro Specs (MANDATORY)** - Before writing ANY code:

- New features: Create a Kiro Feature Spec (requirements.md → design.md → tasks.md)
- Bug fixes: Create a Kiro Bugfix Spec (bugfix.md → design.md → tasks.md)
- Never skip the spec phase. Code without a spec will not be accepted.

**TODO List (MANDATORY)** - Always use the `todo_list` tool:

- Create a persistent TODO list for every multi-step task
- Mark tasks as completed immediately after finishing them
- Never work on multi-step tasks without an active TODO list

**Chain of Thought (MANDATORY)** - Always use the `thinking` tool:

- Before complex decisions, multi-step changes, or architectural choices
- Break problems down into steps before acting
- Document reasoning for non-obvious decisions

**Rule Acknowledgment** - When acting based on a steering rule:

- Print "Rule used: `filename.md` (ID)" at start of response
- For multiple rules: "Rule used: `file1.md` (ID1), `file2.md` (ID2)"
- Don't mention rules generically, only cite specific ones used

**Rule Checking** - Always review steering docs before:

- Using any tool
- Responding to requests
- Making code changes

**Response Format (MANDATORY)** - After completing any code/build/fix task, ALWAYS end with:

1. **Summary**: Brief description of what was done
2. **Tools & MCP Servers Used**: List every tool, MCP server, and subagent invoked
3. **Recommended Next Steps**: 2-5 actionable next steps the user should consider
