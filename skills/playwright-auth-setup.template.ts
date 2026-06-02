// tests/e2e/auth.setup.ts — sample programmatic-auth setup project
//
// Aligns with Playwright E2E Standards in steering/development-workflow.md:
//   - Programmatic login via API + storageState — never UI login
//   - Save state once, reuse across all tests via use.storageState
//   - Secrets from process.env, not embedded in tests
//
// This file is matched by `testMatch: /auth\.setup\.ts/` in playwright.config.ts.
// It runs once before any browser project and produces playwright/.auth/user.json,
// which every test then loads via use.storageState.
//
// CDK app deployed via deploy.sh provides the API at process.env.BASE_URL/api or
// at a Cognito Identity Pool — choose the auth flow that matches your stack.

import { test as setup, expect } from '@playwright/test';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const STORAGE_STATE_FILE = 'playwright/.auth/user.json';
const BASE_URL = process.env.BASE_URL ?? 'http://localhost:5173';

// Required env vars — set these in .env or in your CI secrets:
//   TEST_USER_EMAIL=test+e2e@example.com
//   TEST_USER_PASSWORD=...
//   COGNITO_USER_POOL_ID=us-east-1_xxxxx        (if using Cognito)
//   COGNITO_CLIENT_ID=xxxxx                     (if using Cognito)
//   COGNITO_REGION=us-east-1                    (if using Cognito)

setup('authenticate', async ({ request, page }) => {
  const email = process.env.TEST_USER_EMAIL;
  const password = process.env.TEST_USER_PASSWORD;
  if (!email || !password) {
    throw new Error('TEST_USER_EMAIL and TEST_USER_PASSWORD must be set for auth.setup.ts to run.');
  }

  // ---------------------------------------------------------------------------
  // Option A: Cognito User Pools (USER_PASSWORD_AUTH or USER_AUTH)
  // ---------------------------------------------------------------------------
  // Use the AWS SDK in Node, OR call the Cognito InitiateAuth REST endpoint directly.
  // This example uses the REST endpoint — no @aws-sdk/client-cognito-identity-provider
  // dependency needed in test code.
  //
  // const cognitoEndpoint = `https://cognito-idp.${process.env.COGNITO_REGION}.amazonaws.com/`;
  // const authResponse = await request.post(cognitoEndpoint, {
  //   headers: {
  //     "Content-Type": "application/x-amz-json-1.1",
  //     "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth",
  //   },
  //   data: {
  //     AuthFlow: "USER_PASSWORD_AUTH",
  //     ClientId: process.env.COGNITO_CLIENT_ID,
  //     AuthParameters: { USERNAME: email, PASSWORD: password },
  //   },
  // });
  // const { AuthenticationResult } = await authResponse.json();
  // const idToken = AuthenticationResult.IdToken;
  // const accessToken = AuthenticationResult.AccessToken;
  // const refreshToken = AuthenticationResult.RefreshToken;

  // ---------------------------------------------------------------------------
  // Option B: Custom backend (POST /api/auth/login → { token, refreshToken })
  // ---------------------------------------------------------------------------
  const loginResponse = await request.post(`${BASE_URL}/api/auth/login`, {
    data: { email, password },
  });
  expect(
    loginResponse.ok(),
    `Login failed: ${loginResponse.status()} ${await loginResponse.text()}`,
  ).toBe(true);
  const { token, refreshToken, user } = await loginResponse.json();

  // ---------------------------------------------------------------------------
  // Persist auth state into storageState so every spec inherits a logged-in user
  // ---------------------------------------------------------------------------
  // Most apps store the token in localStorage or as a cookie. Match what your app does.
  await page.goto(BASE_URL);
  await page.evaluate(
    ({ token, refreshToken, user }) => {
      localStorage.setItem('auth_token', token);
      if (refreshToken) localStorage.setItem('refresh_token', refreshToken);
      if (user) localStorage.setItem('auth_user', JSON.stringify(user));
    },
    { token, refreshToken, user },
  );

  // Verify the app recognizes the session by navigating to a protected page.
  await page.goto(`${BASE_URL}/dashboard`);
  await expect(page.getByTestId('dashboard-page')).toBeVisible({ timeout: 10_000 });

  // Save storage state. .auth/ is in .gitignore (see skills/gitignore.template).
  mkdirSync(dirname(STORAGE_STATE_FILE), { recursive: true });
  await page.context().storageState({ path: STORAGE_STATE_FILE });

  // Optional: write a separate file with just the token for direct API calls in specs.
  writeFileSync('playwright/.auth/token.json', JSON.stringify({ token, refreshToken }, null, 2));
});

// ---------------------------------------------------------------------------
// Anti-patterns this template avoids:
// ---------------------------------------------------------------------------
// ❌  await page.goto('/login'); await page.fill(...); await page.click(...);
//    UI login is slow, flaky, and re-runs on every spec. Use API + storageState.
//
// ❌  Hard-coded credentials.
//    Always pull from process.env. Never commit creds to the test file.
//
// ❌  Multiple users authenticated at once.
//    For multi-user scenarios, create a second setup project (e.g.,
//    auth-admin.setup.ts) that writes to playwright/.auth/admin.json,
//    then use storageState: 'playwright/.auth/admin.json' on the
//    admin-only project.
