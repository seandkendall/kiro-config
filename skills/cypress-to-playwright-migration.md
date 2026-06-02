---
name: cypress-to-playwright-migration
description: Step-by-step runbook for porting an existing Cypress E2E test suite to Playwright. Use when an existing project needs to migrate Cypress tests to Playwright following the v0.12.0 standards (data-testid selectors, storageState auth, expect.poll waits). Covers selectors, auth, network mocking, fixtures, custom commands, CI, package.json, gitignore.
---

# Cypress → Playwright Migration

Step-by-step runbook for porting an existing Cypress test suite to Playwright. This config standardized on Playwright in v0.12.0 (Cypress agent removed, `data-cy` → `data-testid`, programmatic auth via `storageState`, etc.). For NEW projects, just start with Playwright — this runbook is for migrating existing Cypress suites.

## Pre-flight

Before starting:

- Existing Cypress test suite in `cypress/e2e/*.cy.ts` (or similar)
- Working `cypress.config.ts` with `baseUrl`, env vars, etc.
- All current Cypress tests passing
- A non-production branch to do the migration on
- Reviewed `steering/development-workflow.md` "Playwright E2E Standards"

## Migration Overview

| Cypress                       | Playwright                                           | Notes                                  |
| ----------------------------- | ---------------------------------------------------- | -------------------------------------- |
| `cypress/e2e/*.cy.ts`         | `tests/e2e/*.spec.ts`                                | Different file extension and directory |
| `cypress/pages/*.ts`          | `tests/e2e/pages/*.ts`                               | Page Objects move with tests           |
| `cypress/fixtures/*.json`     | `tests/e2e/fixtures/*.json`                          | Same purpose                           |
| `cypress/support/commands.ts` | `tests/e2e/fixtures/test.ts`                         | Custom commands → Playwright fixtures  |
| `cypress.config.ts`           | `playwright.config.ts`                               | Different schema (see template)        |
| `data-cy="..."`               | `data-testid="..."`                                  | Selector attribute changes             |
| `cy.get('[data-cy=foo]')`     | `page.getByTestId('foo')`                            | Native Playwright API                  |
| `cy.session()`                | `storageState`                                       | Save/load auth state                   |
| `cy.intercept()`              | `page.route()`                                       | Route mocking                          |
| `cy.wait('@alias')`           | `page.waitForResponse()` or `expect.poll()`          | Network waits                          |
| `cy.wait(ms)`                 | NEVER (use `expect.toBeVisible()`)                   | Timeout-based waits banned             |
| `cy.env('FOO')`               | `process.env.FOO`                                    | No Cypress-equivalent env helper       |
| `@cypress/code-coverage`      | `playwright-coverage` or `monocart-coverage-reports` | Coverage tooling                       |

## Step-by-Step

### 1. Install Playwright + remove Cypress

```bash
# Install Playwright
npm install -D @playwright/test
npx playwright install --with-deps  # Install browser binaries

# Optional: V8 coverage reporter
npm install -D monocart-coverage-reports

# Optional: accessibility assertions
npm install -D @axe-core/playwright

# Remove Cypress (after verifying tests are ported — see step 9)
# npm uninstall cypress @cypress/code-coverage
```

### 2. Generate `playwright.config.ts`

Copy `skills/playwright-config.template.ts` to your project root as `playwright.config.ts` and customize. Key items to update:

- `BASE_URL` env var (used in setup project + `use.baseURL`)
- `testIdAttribute: "data-testid"` (Playwright default; explicit for clarity)
- `projects[]` — pick which browsers + devices you want covered
- `webServer` — your dev-server command (`npm run dev` for Vite, `next dev`, etc.)

### 3. Move directory structure

```bash
mkdir -p tests/e2e/pages tests/e2e/fixtures
mv cypress/e2e/*.cy.ts tests/e2e/
# Rename .cy.ts → .spec.ts in batch:
cd tests/e2e
for f in *.cy.ts; do mv "$f" "${f%.cy.ts}.spec.ts"; done
cd -

# Move Page Objects
mv cypress/pages/*.ts tests/e2e/pages/

# Move fixtures
mv cypress/fixtures/* tests/e2e/fixtures/
```

### 4. Migrate selectors: `data-cy` → `data-testid`

In your React/frontend source:

```bash
# Bulk replace data-cy with data-testid (verify with git diff before committing)
grep -rl 'data-cy=' src/ | xargs sed -i '' 's/data-cy=/data-testid=/g'
```

> **Note:** This config (v0.12.0+) uses `data-testid` as the canonical attribute. If you have a strong reason to keep `data-cy` (e.g., shared with another codebase), you can instead set `testIdAttribute: "data-cy"` in `playwright.config.ts` and skip this step. But default to `data-testid` for new projects.

### 5. Migrate test code: spec-by-spec

Convert each test using these mechanical substitutions. Example:

**Before (Cypress):**

```typescript
describe('Invoice creation', () => {
  beforeEach(() => {
    cy.session('user', () => {
      cy.request('POST', '/api/auth/login', { email, password });
    });
    cy.visit('/invoices/new');
  });

  it('creates an invoice', () => {
    cy.intercept('POST', '/api/invoices', { fixture: 'created-invoice.json' }).as('create');
    cy.get('[data-cy=invoice-amount-input]').type('100.00');
    cy.get('[data-cy=invoice-submit]').click();
    cy.wait('@create');
    cy.get('[data-cy=success-toast]').should('be.visible');
  });
});
```

**After (Playwright):**

```typescript
import { test, expect } from '@playwright/test';
import createdInvoice from '../fixtures/created-invoice.json';

// Auth handled by tests/e2e/auth.setup.ts → playwright/.auth/user.json
// (no per-test session setup needed)

test.beforeEach(async ({ page }) => {
  await page.goto('/invoices/new');
});

test('creates an invoice', async ({ page }) => {
  await page.route('**/api/invoices', (route) =>
    route.fulfill({ status: 201, json: createdInvoice }),
  );
  await page.getByTestId('invoice-amount-input').fill('100.00');
  await page.getByTestId('invoice-submit').click();
  await page.waitForResponse('**/api/invoices');
  await expect(page.getByTestId('success-toast')).toBeVisible();
});
```

Key transformations:

- `describe` → no wrapper needed (specs are isolated by file)
- `beforeEach` → `test.beforeEach`
- `cy.session()` → handled once in `auth.setup.ts`
- `cy.visit()` → `page.goto()`
- `cy.get('[data-cy=foo]')` → `page.getByTestId('foo')`
- `.type()` → `.fill()`
- `.click()` → `await .click()` (everything async)
- `cy.intercept()` → `page.route()`
- `cy.wait('@alias')` → `page.waitForResponse()`
- `.should('be.visible')` → `await expect().toBeVisible()`

### 6. Migrate auth: `cy.session()` → `storageState`

Copy `skills/playwright-auth-setup.template.ts` to `tests/e2e/auth.setup.ts` and customize for your auth flow (Cognito, custom JWT, etc.). The setup project runs once before all tests and produces `playwright/.auth/user.json`. Every test reuses it via `use.storageState`.

This is the biggest mental shift from Cypress — there's no per-test login. The `storageState` is loaded by Playwright's browser context before the spec runs.

### 7. Migrate Page Objects

Cypress Page Objects extend with `cy` chained calls. Playwright Page Objects accept a `Page` instance:

**Before:**

```typescript
// cypress/pages/InvoicePage.ts
export class InvoicePage {
  visit() {
    cy.visit('/invoices');
    return this;
  }
  createInvoice(amount: string) {
    cy.get('[data-cy=invoice-amount-input]').type(amount);
    cy.get('[data-cy=invoice-submit]').click();
  }
}
```

**After:**

```typescript
// tests/e2e/pages/InvoicePage.ts
import { Page, expect } from '@playwright/test';
export class InvoicePage {
  constructor(private page: Page) {}
  async visit() {
    await this.page.goto('/invoices');
  }
  async createInvoice(amount: string) {
    await this.page.getByTestId('invoice-amount-input').fill(amount);
    await this.page.getByTestId('invoice-submit').click();
  }
}

// In specs:
const invoices = new InvoicePage(page);
await invoices.visit();
await invoices.createInvoice('100.00');
```

### 8. Migrate custom commands: `Cypress.Commands.add` → Playwright fixtures

Cypress's `Cypress.Commands.add('login', () => {...})` becomes a Playwright fixture:

```typescript
// tests/e2e/fixtures/test.ts
import { test as base } from '@playwright/test';
import { InvoicePage } from '../pages/InvoicePage';

type Fixtures = {
  invoicePage: InvoicePage;
};

export const test = base.extend<Fixtures>({
  invoicePage: async ({ page }, use) => {
    await use(new InvoicePage(page));
  },
});

export { expect } from '@playwright/test';
```

Then specs import from your fixtures file:

```typescript
import { test, expect } from '../fixtures/test';

test('creates an invoice', async ({ invoicePage }) => {
  await invoicePage.visit();
  await invoicePage.createInvoice('100.00');
});
```

### 9. Run both suites side-by-side

Before deleting Cypress, run BOTH suites against the same baseURL and verify Playwright covers everything Cypress did:

```bash
# Old Cypress suite — should still pass during migration
npx cypress run

# New Playwright suite
npx playwright test
```

Compare counts — if Playwright has fewer tests, you've missed some specs. Once Playwright is at parity:

```bash
npm uninstall cypress @cypress/code-coverage
rm -rf cypress/ cypress.config.ts cypress.json
```

### 10. Update `.gitignore`

Add Playwright artifacts (replace any `cypress/` lines):

```
# Playwright
test-results/
playwright-report/
playwright/.auth/
playwright/.cache/
```

The full ready-to-copy version is in `skills/gitignore.template`.

### 11. Update `package.json` scripts

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:codegen": "playwright codegen $BASE_URL",
    "test:e2e:report": "playwright show-report"
  }
}
```

### 12. Update CI

Replace any `cypress/included` Docker image or `cypress run` step with Playwright:

```yaml
# Pseudo-CI (NOT recommending GitHub Actions per the no-CI/CD steering rule —
# this is just an example of the script you'd run wherever you run E2E)
- run: npx playwright install --with-deps chromium
- run: npx playwright test
- if: failure()
  run: npx playwright show-report
```

### 13. Update accessibility tests

Cypress + axe = `cy.injectAxe()` + `cy.checkA11y()`. Playwright + axe = `@axe-core/playwright`:

```typescript
import AxeBuilder from '@axe-core/playwright';

test('dashboard has no a11y violations', async ({ page }) => {
  await page.goto('/dashboard');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

## Common Gotchas

- **`page.click()` is auto-waiting** — you don't need `.should('be.visible')` before clicking. Playwright waits for the element to be actionable.
- **`page.fill()` clears before typing** — `cy.type()` appended to existing value. To append in Playwright, use `page.locator(...).type('...')` (different semantics).
- **`expect()` is async-aware** — `await expect(locator).toBeVisible()` retries automatically. No `.should()` needed.
- **No `cy.then()` chain** — write straight async/await. Playwright handles parallelism via `test.describe.parallel()` and project-level `fullyParallel`.
- **Network mocking returns are different** — `cy.intercept(..., { fixture: 'foo.json' })` becomes `route.fulfill({ status: 200, json: fixture })`.
- **No `cy.contains('text')`** — use `page.getByText('text')` or `page.locator(':text("foo")')`. Prefer `getByRole()` and `getByLabel()` for accessibility.
- **No `cy.tick()` for fake timers** — Playwright doesn't ship fake timers. Use sinon or vitest fake timers exposed via `page.evaluate()`.

## Rollback

If Playwright migration stalls in the middle:

1. Keep both `cypress/` and `tests/e2e/` directories
2. Keep `cypress.config.ts` AND `playwright.config.ts`
3. Keep both runners in `package.json` scripts (`test:e2e:cypress` + `test:e2e:playwright`)
4. Migrate one spec file at a time — each commit is a partial migration
5. Only delete Cypress after ALL specs are ported and you've run both suites against the same environment for a couple of full test runs

## Cross-References

- `steering/development-workflow.md` — Playwright E2E Standards section (canonical rules)
- `steering/troubleshooting.md` — Playwright E2E Issues section
- `skills/playwright-config.template.ts` — copy-paste-ready config
- `skills/playwright-auth-setup.template.ts` — copy-paste-ready auth setup project
- `skills/testing-patterns.md` — Playwright Quick Reference
- `skills/gitignore.template` — includes Playwright artifact paths
