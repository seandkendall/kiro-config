---
inclusion: auto
name: development-quality-gates
description: 'Build/test/lint quality gates and engineering standards: daily dependency upgrades, package management, pre-deployment quality gate (lint, build, pytest coverage, Playwright E2E, deprecations, audits), Playwright E2E standards (data-testid, storageState, no waitForTimeout), testing standards and test organization, documentation requirements, code review checklist, /code onboarding. Use when building, testing, linting, upgrading dependencies, reviewing code, or preparing a deployment.'
---

# Development Quality Gates & Standards

> Core interaction rules (specs-first, TODO lists, timestamps, response format) live in
> `development-workflow.md` (always loaded). This doc holds the build/test/quality detail.

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
4. **Playwright E2E**: `npx playwright test` — target 100% coverage via `playwright-coverage` or `monocart-coverage-reports`
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

## Onboarding to an Existing Project

When opening an unfamiliar codebase for the first time, run `/code overview` to get a high-level structural snapshot in seconds — symbols, top-level files, language breakdown, key entry points. This is faster than manually reading the README + grepping the code, and works on 18 languages out of the box (Python, TS/JS, Rust, Go, Java, Kotlin, Swift, Ruby, PHP, etc.).

For deeper exploration without LSP setup:

- `/code search <symbol>` — find a class, function, or method by name
- `/code overview` (with `--silent` for cleaner output) — quick structural map
- The `code` tool's `pattern_search` and `pattern_rewrite` use AST patterns (not regex) — safer refactors

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
- Playwright E2E tests: `tests/e2e/*.spec.ts`
- Playwright Page Objects: `tests/e2e/pages/*.ts`

## Playwright E2E Standards

**Playwright is mandatory for all E2E testing.**

**Selectors**: Always use `data-testid` attributes — never class, id, or tag. Prefer `page.getByTestId()` over `page.locator()` for testid lookups.
**Isolation**: Each test runs independently. Use `test.beforeEach`, never `test.afterEach` for cleanup. Set `fullyParallel: true` in `playwright.config.ts`.
**Auth**: Programmatic login via API + `storageState` — never UI login. Save state once in a setup project, reuse across all tests via `use.storageState`.
**Waiting**: Never `page.waitForTimeout(ms)`. Use `expect(locator).toBeVisible()` (auto-retries), `page.waitForResponse()`, or `expect.poll()`.
**Config**: Set `baseURL` in `playwright.config.ts`. Use environment variables (process.env) for secrets, NOT a `cy.env()` equivalent.
**Coverage**: Target 100%. Use `playwright-coverage` or Chromium V8 coverage with `monocart-coverage-reports`.
**Accessibility**: Use `@axe-core/playwright` library inside specs (no separate a11y MCP needed).
**Parallel**: For multiple browser sessions via the Playwright MCP, pass `--isolated` to avoid the persistent-profile single-browser lock.

## Documentation Requirements

- Every project MUST have a README.md with: purpose, prerequisites, setup, deployment, architecture overview
- Every Lambda function MUST have a docstring explaining its trigger, input, output, and side effects
- Every React component MUST have a JSDoc comment describing its props and usage
- Every API endpoint MUST be documented in an OpenAPI spec or GraphQL schema with descriptions

## Code Review Checklist

Before considering any feature complete, verify:

- [ ] All new components have `data-testid` attributes for Playwright selectors
- [ ] All new API endpoints are documented in the OpenAPI spec
- [ ] All new Lambda functions use Powertools (Logger, Tracer, Metrics)
- [ ] All new DynamoDB operations use parameterized queries (no string concatenation)
- [ ] No hardcoded values — all config via env vars or SSM
- [ ] No `console.log` in production code — use structured logging
- [ ] Accessibility: keyboard navigable, proper ARIA, color contrast passes
