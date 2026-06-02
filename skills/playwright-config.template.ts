// playwright.config.ts — sample template for projects deployed via this Kiro CLI config
//
// Copy to your project root and customize. Aligns with the Playwright E2E Standards in
// steering/development-workflow.md:
//   - data-testid selectors via page.getByTestId()
//   - storageState programmatic auth (no UI login)
//   - fullyParallel + retries on CI
//   - baseURL from env (process.env), not hard-coded
//   - V8 coverage via monocart-coverage-reports (target 100%)
//   - @axe-core/playwright in specs for accessibility (no separate a11y MCP)

import { defineConfig, devices } from '@playwright/test';

const BASE_URL = process.env.BASE_URL ?? 'http://localhost:5173';
const CI = !!process.env.CI;

export default defineConfig({
  testDir: './tests/e2e',
  outputDir: './test-results',

  // Each test runs independently. Set --workers to control parallelism;
  // fullyParallel splits even within a single spec file.
  fullyParallel: true,
  workers: CI ? 4 : undefined,

  // Retries only on CI — local runs surface flakes immediately.
  retries: CI ? 2 : 0,

  // Fail fast on .only() left in committed tests.
  forbidOnly: CI,

  // Default per-action timeout. Tighten if your app is fast.
  timeout: 30_000,
  expect: { timeout: 10_000 },

  // Reporters
  reporter: CI
    ? [
        ['html', { outputFolder: 'playwright-report', open: 'never' }],
        ['github'],
        ['json', { outputFile: 'test-results/results.json' }],
      ]
    : [['html', { open: 'never' }], ['list']],

  use: {
    baseURL: BASE_URL,

    // baseURL is used; never hard-code URLs in tests.
    // Use environment variables (process.env) for secrets — there is NO Playwright
    // equivalent of `cy.env()`. Reference secrets like process.env.TEST_USER_EMAIL.

    trace: 'on-first-retry', // capture trace zip when a test retries
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // Programmatic auth: every test reuses storageState produced by tests/e2e/auth.setup.ts
    storageState: 'playwright/.auth/user.json',

    // Sets the testIdAttribute used by page.getByTestId('...')
    testIdAttribute: 'data-testid',

    // Auto-wait for network idle on navigation. Avoids many waitForTimeout calls.
    navigationTimeout: 30_000,
    actionTimeout: 10_000,
  },

  projects: [
    // Setup project: produces storageState. Runs once before everything else.
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },

    // Browser projects depend on setup — they reuse the storageState.
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup'],
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
      dependencies: ['setup'],
    },

    // Mobile coverage at the standard breakpoints from accessibility-standards.md
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 7'] },
      dependencies: ['setup'],
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 15'] },
      dependencies: ['setup'],
    },
  ],

  // If your dev server is not already running, start it. Local-only convenience.
  webServer: CI
    ? undefined
    : {
        command: 'npm run dev',
        url: BASE_URL,
        reuseExistingServer: true,
        timeout: 120_000,
      },
});
