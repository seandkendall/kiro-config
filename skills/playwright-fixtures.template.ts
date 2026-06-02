// tests/e2e/fixtures/test.ts — sample Playwright fixtures template
//
// Replaces Cypress's `Cypress.Commands.add('foo', ...)` pattern. Fixtures inject
// reusable objects (Page Objects, mocked APIs, seeded test data) into your tests.
//
// Usage in a spec:
//   import { test, expect } from '../fixtures/test';
//   test('creates an invoice', async ({ invoicePage, mockedApi }) => { ... });
//
// Aligns with the v0.12.0 standards in steering/development-workflow.md:
//   - Test isolation (every fixture re-instantiated per test by default)
//   - data-testid selectors via page.getByTestId()
//   - No UI login (storageState handled in auth.setup.ts)
//   - process.env for secrets (no cy.env() equivalent)
//
// Companion files:
//   - skills/playwright-config.template.ts (playwright.config.ts)
//   - skills/playwright-auth-setup.template.ts (auth.setup.ts)
//   - skills/cypress-to-playwright-migration.md (full migration runbook)

import { test as base, expect, type Page, type APIRequestContext } from '@playwright/test';

// ---------------------------------------------------------------------------
// Page Objects (one per major page in your app)
// ---------------------------------------------------------------------------

class DashboardPage {
  constructor(private readonly page: Page) {}

  async visit() {
    await this.page.goto('/dashboard');
    await expect(this.page.getByTestId('dashboard-page')).toBeVisible();
  }

  async openInvoiceForm() {
    await this.page.getByTestId('invoice-create-button').click();
  }
}

class InvoicePage {
  constructor(private readonly page: Page) {}

  async visit() {
    await this.page.goto('/invoices/new');
    await expect(this.page.getByTestId('transaction-form')).toBeVisible();
  }

  async fillAmount(amount: string) {
    await this.page.getByTestId('invoice-amount-input').fill(amount);
  }

  async submit() {
    await this.page.getByTestId('invoice-submit').click();
  }

  async expectSuccessToast() {
    await expect(this.page.getByTestId('invoice-success-toast')).toBeVisible();
  }
}

// ---------------------------------------------------------------------------
// Test data factory (replaces cy.fixture and ad-hoc test-data helpers)
// ---------------------------------------------------------------------------

class TestData {
  constructor(private readonly request: APIRequestContext) {}

  /**
   * Seed an invoice via the API. Returns the created invoice's ID for use in
   * a test. Cleaned up automatically when the fixture tears down.
   */
  async seedInvoice(overrides: Partial<{ amount: number; vendor: string }> = {}) {
    const baseURL = process.env.BASE_URL ?? 'http://localhost:5173';
    const response = await this.request.post(`${baseURL}/api/invoices`, {
      data: {
        amount: overrides.amount ?? 100.0,
        vendor: overrides.vendor ?? 'Test Vendor Inc.',
        ...overrides,
      },
    });
    expect(response.ok()).toBe(true);
    return await response.json();
  }
}

// ---------------------------------------------------------------------------
// Mocked API helpers (replaces cy.intercept patterns scattered in specs)
// ---------------------------------------------------------------------------

class MockedApi {
  constructor(private readonly page: Page) {}

  /** Mock a POST to /api/invoices. Returns the route handler so tests can `.unroute()` later if needed. */
  async stubCreateInvoice(response: { id: string; amount: number }, status = 201) {
    await this.page.route('**/api/invoices', (route) => {
      if (route.request().method() === 'POST') {
        return route.fulfill({ status, json: response });
      }
      return route.continue();
    });
  }

  /** Mock a GET to /api/invoices. */
  async stubListInvoices(response: { items: unknown[] }) {
    await this.page.route('**/api/invoices**', (route) => {
      if (route.request().method() === 'GET') {
        return route.fulfill({ status: 200, json: response });
      }
      return route.continue();
    });
  }

  /** Force-fail a request to test error states. */
  async stubFailure(urlPattern: string | RegExp, status = 500, message = 'Internal Server Error') {
    await this.page.route(urlPattern, (route) =>
      route.fulfill({ status, json: { error: message } }),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixture types — what the test signature receives in the destructured arg
// ---------------------------------------------------------------------------

type Fixtures = {
  dashboardPage: DashboardPage;
  invoicePage: InvoicePage;
  testData: TestData;
  mockedApi: MockedApi;
};

// ---------------------------------------------------------------------------
// Extended `test` — re-export with custom fixtures wired in
// ---------------------------------------------------------------------------

export const test = base.extend<Fixtures>({
  dashboardPage: async ({ page }, use) => {
    await use(new DashboardPage(page));
  },

  invoicePage: async ({ page }, use) => {
    await use(new InvoicePage(page));
  },

  testData: async ({ request }, use) => {
    const data = new TestData(request);
    await use(data);
    // Add cleanup here if your API supports it:
    //   await request.delete(`${BASE_URL}/api/test-data/${data.runId}`);
  },

  mockedApi: async ({ page }, use) => {
    await use(new MockedApi(page));
    // Routes auto-clean when the page closes
  },
});

// Re-export expect so specs only import from this file
export { expect };

// ---------------------------------------------------------------------------
// Sample spec usage:
//
//   import { test, expect } from '../fixtures/test';
//
//   test('creates an invoice end-to-end', async ({ invoicePage, mockedApi }) => {
//     await mockedApi.stubCreateInvoice({ id: 'inv_123', amount: 100 });
//     await invoicePage.visit();
//     await invoicePage.fillAmount('100.00');
//     await invoicePage.submit();
//     await invoicePage.expectSuccessToast();
//   });
//
//   test('shows error toast on API failure', async ({ invoicePage, mockedApi }) => {
//     await mockedApi.stubFailure('**/api/invoices', 500);
//     await invoicePage.visit();
//     await invoicePage.fillAmount('100.00');
//     await invoicePage.submit();
//     await expect(page.getByTestId('invoice-error')).toBeVisible();
//   });
// ---------------------------------------------------------------------------
