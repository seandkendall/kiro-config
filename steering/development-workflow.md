---
inclusion: always
name: development-workflow
description: Mandatory development rules: daily dependency upgrades, no time estimates, timestamped output, Kiro Specs before code, file modification in-place (no _v2/_new files), pre-deployment quality gate, /code overview onboarding, Playwright E2E standards, response format with post-task recommendations. Use for every code/build/fix task.
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

**File Modification Rule** - When modifying existing code, ALWAYS edit files in-place. NEVER create duplicate files like `file_new.py`, `file_modified.py`, `file_v2.py`, `file_backup.py`, or `ClassName_updated.java` alongside the original. Check if a file exists before creating it — if it exists, modify it.

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

## Kiro Interaction Rules

**No Time Estimates (MANDATORY)** - Never provide time estimates:

- Do NOT estimate hours, days, weeks, story points, or sprint sizes for any task
- Do NOT say things like "this is 90-120 hours of work" or "this will take X days"
- Do NOT include effort sizing (small/medium/large) unless the user explicitly asks
- Just execute the work. Time estimates are unreliable for AI-assisted development and add noise
- If the user asks for complexity, respond with scope (number of files, dependencies, risks) — not time

**Timestamped Output (MANDATORY)** - Stamp your output with the current local time so the user can see WHEN each comment, decision, or status update was made:

- Use the current time provided in the session context (the `Current time:` context entry) — it carries the user's timezone offset (e.g., `2026-06-13T13:11:02-06:00`).
- Print a timestamp at the **start of every response**, and again before major status updates within a long-running response (e.g., before each phase of a multi-step task, before/after a long tool run, when reporting a result).
- Format: `[HH:MM:SS TZ]` or `[YYYY-MM-DD HH:MM:SS -06:00]` — keep it compact and include the timezone offset or abbreviation so it's unambiguous. Example: `[13:11:02 MDT] Starting the migration…`
- Apply this to feedback, reasoning/thinking narration, progress updates, and final summaries.
- This is NOT a time estimate — it's a wall-clock timestamp of when the comment was written. It does not conflict with the "No Time Estimates" rule above (which bans predicting how _long_ work will take). Printing the current time is always allowed and encouraged; predicting durations is still banned.
- If the session context does not include a current time for the turn, omit the timestamp rather than guessing — never fabricate a time.

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
3. **Recommended Next Steps**: Follow the format in `post-task-recommendations.md` — split into "for the user" (optional) and "for the AI Agent" (mandatory, ≥10 items, sorted by priority)

**Documentation Sync (MANDATORY)** - When you make changes to this repo:

- **ALWAYS update `CHANGELOG.md`** with a new entry for the change. If a dated entry for today already exists, append to it; otherwise create a new one. Group entries under `### Added`, `### Changed`, `### Removed`, `### Fixed` as appropriate.
- **ALWAYS update `README.md`** when the change affects:
  - The agent table (additions, removals, renames)
  - The skills count or table
  - The MCP server table
  - Required environment variables
  - Prerequisites or installation steps
  - Configuration defaults (model, settings)
- Both updates happen in the SAME commit as the underlying change — do not defer to a separate commit
- This rule applies to ALL agents, ALL subagents, and ALL sessions

**Settings Change Confirmation (MANDATORY)** - Kiro CLI silently mutates `settings/cli.json` during normal use (e.g., it can flip `chat.greeting.enabled` between sessions). When `git add -A` would sweep up such a change:

- ALWAYS surface the diff in your response BEFORE committing
- ALWAYS ask the user whether the change is intentional, unless the change is clearly part of the current task (e.g., the user asked to bump the default model)
- NEVER auto-revert a settings change just because it wasn't explicitly requested — the user may have made the change deliberately outside this session. Surface, ask, then act on their answer.
- Prefer `git add <specific-file>` over `git add -A` when the task scope is narrow, to avoid sweeping up unrelated state mutations entirely
- This rule also applies to: `agents/*.json` (Kiro CLI may rewrite formatting on agent edits) and any other config files that the CLI itself manages

**Stage Specific Files (MANDATORY)** - For narrow-scope changes (one file, one feature), use `git add <files>` over `git add -A`. Three real stowaways have been caught in this project's history (`settings/survey_state.json`, two `chat.greeting.enabled` flips) — each was caused by `git add -A` sweeping in unrelated state. The defensive default is to stage only what you intentionally changed.
