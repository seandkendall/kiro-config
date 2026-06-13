# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.13.2] - master-demo prompt rewrite (tighter, no time budget)

### Changed

- **`prompts/master-demo.md` rewritten** — condensed from ~124 lines to a tighter, scannable prompt. Substantive improvements:
  - "Deploy FIRST, validate AFTER" — skip `cdk synth` / local pre-deploy checks; the deploy + post-deploy live sweep are the only validation
  - Minimal `cdk.json` (`{"app": "python3 app.py"}`, no feature-flag block), unpinned `requirements.txt` (no install-then-introspect)
  - `deploy.sh` must be **bash-3.2-safe** (macOS default — no empty-array `[@]` expansion under `set -u`)
  - "Lambdalith" single-file Lambda, latest Python runtime, stdlib `logging`
  - CORS guidance clarified: configure on `HttpApi` via `cors_preflight`; do NOT set `Access-Control-*` headers in the Lambda (gateway adds them — avoids duplicates)
  - Consolidated NEVER list into one dense line
  - Tighter 5-step FLOW (plan → write all files → deploy → sweep → report URL)
  - **No time budget** — qualitative "Speed is the priority" framing kept, but the `~7 minutes` numeric target was removed to stay consistent with the v0.11.1 "remove all time budgets" decision and the v0.13.1 "No Time Estimates" / "Timestamped Output" global rule

### Added

- **`.gitignore`**: `*.bak`, `*.backup`, `* copy.*` patterns — stowaway prevention for editor/manual backup files (caught a stray `prompts/master-demo.md.bak`)

## [0.13.1] - Timestamped output rule

### Added

- **`Timestamped Output (MANDATORY)`** rule in `steering/development-workflow.md` (inclusion: always — applies to every agent, every session). Agents now stamp their output with the current local time so the user can see WHEN each comment, decision, or status update was made.
  - Uses the `Current time:` value from the session context (carries the user's timezone offset)
  - Timestamp at the start of every response + before major status updates in long-running responses (per-phase, before/after long tool runs, when reporting results)
  - Compact format: `[HH:MM:SS TZ]` or `[YYYY-MM-DD HH:MM:SS -06:00]`, always with the timezone offset/abbreviation
  - Applies to feedback, reasoning narration, progress updates, and final summaries
  - **Explicitly distinguished from the "No Time Estimates" ban** — a wall-clock timestamp of when a comment was written is NOT a prediction of how long work will take. Printing the current time is encouraged; predicting durations stays banned.
  - If the turn's context has no current time, omit the timestamp rather than fabricate one
- Added "timestamped output" to the doc's frontmatter `description` for discoverability

## [0.13.0] - Demo agent consolidation (one master-demo)

### Removed

- **Orchestrator `master-demo` agent deleted** — `agents/master-demo.json` (the parallel-subagent-showcase version) and its `prompts/master-demo.md`. The two-demo-agent split (orchestrator + single) added complexity without enough payoff; one demo agent is cleaner.

### Changed

- **`master-demo-single` renamed → `master-demo`** (via `git mv`, history preserved). The surviving demo agent is the lean single-agent version: no subagents, only `aws-mcp-server` (Agent Toolkit for AWS) + the `aws-serverless` skill bundle.
  - `agents/master-demo-single.json` → `agents/master-demo.json`
  - `prompts/master-demo-single.md` → `prompts/master-demo.md`
  - Agent `name`: `master-demo-single` → `master-demo`
  - `prompt` URI updated to `file://~/.kiro/prompts/master-demo.md`
  - `description` reworded (dropped "lean variant of master-demo" framing — there's no longer a master-demo to be a variant of)
  - `welcomeMessage` updated to "master-demo ready…"
  - Keyboard shortcut: inherits **`shift+m`** (the mnemonic shortcut freed by deleting the old orchestrator). `ctrl+7` is now free.
  - Prompt self-references updated; the "switch to master-demo for parallel work" fallback now points to the `master` orchestrator (the only orchestrator that fans out to subagents)
- **README**: collapsed the two demo-agent rows into one `master-demo` row; agent count 16 → 15; AWS MCP "All 16 agents" → "All 15 agents"
- **`steering/AGENTS.md`**: collapsed the two "When to Use Which Agent" demo lines into one
- **`steering/aws-standards.md`**: `-y` flag note reworded from "demo orchestrator (`master-demo`)" to just "`master-demo` agent" (it's no longer an orchestrator)

### Counts after consolidation

- **Agents**: 15 shareable (was 16), 20 total on disk (was 21)
- No keyboard shortcut conflicts; `ctrl+7` freed

### Why

The orchestrator demo and single-agent demo had identical hard rules (no UI/WAF/Route53/AppRegistry/Powertools/X-Ray/cdk-nag/Kiro-Specs, always CORS, OpenAPI 3 native) — the only difference was subagent fan-out. Maintaining two near-identical prompts was redundant. The single-agent version is the better default for live demos (one linear thread the audience can follow), and anyone needing parallel orchestration can use the full `master` agent.

## [0.12.3] - apigatewayv2-alpha → stable migration + CDK alpha-module rule

### Changed

- **`prompts/master-demo.md` + `prompts/master-demo-single.md`** — migrated the HTTP API efficiency rule from the deprecated `aws_apigatewayv2_alpha` to stable `aws_cdk.aws_apigatewayv2` (in `aws-cdk-lib`). The `aws-cdk.aws-apigatewayv2-alpha` PyPI package was retired in Dec 2023 (Development Status: Inactive, last release 2.114.1a0) and all constructs graduated to `aws-cdk-lib`. Updated 3 references total:
  - HTTP API construct: `aws_apigatewayv2_alpha.HttpApi` → `aws_cdk.aws_apigatewayv2.HttpApi` (`from aws_cdk import aws_apigatewayv2 as apigwv2`)
  - CORS config: `aws_apigatewayv2_alpha.CorsPreflightOptions` → `apigwv2.CorsPreflightOptions`
  - Added explicit "do NOT use the deprecated alpha package" warnings + pointer to `aws_cdk.aws_apigatewayv2_integrations` for Lambda integrations
- **`steering/AGENTS.md`** — trimmed the verbose "Use when the demo benefits from one continuous thread of work…" clause from the `master-demo-single` routing line (the master-demo vs master-demo-single comparison was removed from the prompt itself; this keeps the docs consistent).
- **`prompts/master-demo-single.md`** — removed the "WHEN TO USE master-demo-single vs master-demo" comparison block (the routing guidance lives in AGENTS.md / README, not in the agent's own prompt).
- **`settings/cli.json`** — restored the trailing newline (matches `.editorconfig` `insert_final_newline = true`).

### Added

- **`steering/aws-standards.md`** — new "CDK Alpha Modules (MANDATORY)" rule under CDK Infrastructure:
  - Always prefer the stable `aws-cdk-lib` module when one exists; verify via `aws___search_documentation` or the module's PyPI page before relying on any `*_alpha` package
  - **Known graduations** (use stable, not alpha): the `aws-cdk.aws-apigatewayv2-alpha` trio → `aws_cdk.aws_apigatewayv2` + `aws_cdk.aws_apigatewayv2_integrations` + `aws_cdk.aws_apigatewayv2_authorizers`
  - **Still alpha** (re-check before use): `aws_lambda_python_alpha` (`PythonFunction`), `aws_servicecatalogappregistry_alpha` (`ApplicationAssociator`)

### Why

A user audit flagged that the demo prompts still referenced `aws-cdk.aws-apigatewayv2-alpha`, which has been deprecated since Dec 2023. Confirmed via PyPI (Development Status: 7 - Inactive) and the current CDK docs (2.252.0) that all three apigatewayv2 submodules now live in `aws-cdk-lib`. Added a general alpha-module rule so future agents check graduation status before pinning any `*_alpha` package.

## [0.12.2] - Playwright migration polish: tooling, regression guard, more templates

### Added

- **README "Local Tooling Required by MCP Servers" table** — new row for **Playwright browsers**: `npx playwright install --with-deps chromium firefox webkit`. Used by the `@playwright/mcp` server on `frontend`, `testing`, and `web-builder` agents. Without this, the MCP starts but every browser-launch action fails.
- **`validate.sh` Step 6: Cypress regression guard** — defensive check that scans every tracked file for `cypress` or `data-cy` references. Allow-list: `CHANGELOG.md` (historical) and `skills/cypress-to-playwright-migration.md` (intentional examples showing what to migrate FROM). If a regression slips through (e.g., someone copies an old test file into the repo), the guard surfaces it with the file paths and a pointer to the migration runbook.
- **`skills/package.json.template`** (111 lines) — copy-paste-ready starter `package.json` for React + Playwright projects deployed via this config. Includes Vite + React 18 + TypeScript, Vitest + RTL for unit tests, Playwright + `@axe-core/playwright` + `monocart-coverage-reports` for E2E with coverage, ESLint flat config, Tailwind CSS, react-hook-form + zod, TanStack Query + Zustand, Premailer/Juice for the email build pipeline. All version pins are placeholders — projects should `npm install <pkg>@latest` per the daily-upgrade rule.
- **`skills/playwright-fixtures.template.ts`** (181 lines) — copy-paste-ready Playwright fixtures file demonstrating the Cypress-custom-commands → Playwright-fixtures migration pattern. Includes:
  - Page Object classes (`DashboardPage`, `InvoicePage`) with constructor-based dependency injection
  - `TestData` factory using `APIRequestContext` for seeding via the API (replaces `cy.fixture` patterns)
  - `MockedApi` helpers (`stubCreateInvoice`, `stubListInvoices`, `stubFailure`) wrapping `page.route()` (replaces scattered `cy.intercept` calls)
  - Sample spec showing how to consume the fixtures in tests

### Verified (no fixes needed)

- `master-demo` and `master-demo-single` NEVER lists already explicitly mention "No Playwright tests" (added in v0.12.0 migration commit). No change required.
- `cy.session()`, `cy.intercept()`, `cy.visit()`, `cy.get()` references in tracked files: all 16 occurrences are intentional and correctly placed inside `skills/cypress-to-playwright-migration.md` (showing what to migrate FROM) or in the CHANGELOG describing the migration table. The new validate.sh Step 6 explicitly allow-lists both files.

### Why

The previous v0.12.0 + v0.12.1 commits completed the Cypress → Playwright migration but left three small gaps that this commit closes:

1. **Local tooling discoverability** — a new contributor cloning the repo might not realize `@playwright/mcp` needs browser binaries installed via a separate command. README table now makes it explicit.
2. **Regression defense** — without an automated check, future contributors could accidentally re-introduce `data-cy` selectors or `cy.*` calls. validate.sh Step 6 makes this loud.
3. **Starter completeness** — projects starting from this config now have copy-paste templates for `playwright.config.ts`, `auth.setup.ts`, `package.json`, AND fixtures pattern. No need to assemble these from memory.

## [0.12.1] - Playwright migration polish

### Added

- **`skills/playwright-config.template.ts`** (113 lines) — copy-paste-ready `playwright.config.ts` matching the v0.12.0 standards: `data-testid` selectors, `storageState` programmatic auth, `fullyParallel`, `retries` on CI, `baseURL` from env, V8 trace + screenshot + video on failure, separate `setup` project for auth, 5 browser projects (chromium / firefox / webkit / mobile-chrome / mobile-safari at the standard breakpoints), `webServer` for local dev.
- **`skills/playwright-auth-setup.template.ts`** (113 lines) — copy-paste-ready `tests/e2e/auth.setup.ts`. Two auth flow examples (Cognito InitiateAuth REST and custom backend `POST /api/auth/login`), localStorage / cookie persistence into `playwright/.auth/user.json`, dashboard verification, secrets from `process.env`. Documents the anti-patterns it avoids (UI login, hard-coded creds).
- **`skills/cypress-to-playwright-migration.md`** (334 lines) — step-by-step runbook for projects with existing Cypress test suites. Covers: install/uninstall, directory structure, `data-cy` → `data-testid` bulk rename, mechanical test transformations table (`cy.get` → `getByTestId`, `cy.intercept` → `page.route`, `cy.session` → `storageState`, `cy.wait('@alias')` → `page.waitForResponse`, etc.), Page Object migration, custom commands → Playwright fixtures, side-by-side run validation before deletion, `.gitignore` / `package.json` / CI updates, accessibility test migration, common gotchas, partial-migration rollback strategy.
- **`prompts/web-builder.md`** — new "PLAYWRIGHT MCP USAGE" paragraph clarifying that web-builder's bundled `@playwright/mcp` is for ad-hoc browser inspection during scaffolding (verifying CloudFront deployments came up, checking shadcn components render, generating selectors via `generate_locator`). Test SUITES still delegate to the `testing` subagent — don't write `tests/e2e/*.spec.ts` directly from web-builder.

### Verified (no fixes needed)

- `master-demo` and `master-demo-single`: confirmed NO browser MCPs in their configs (correct — they explicitly forbid all browser testing). MCP list: `master-demo` has 5 (web-search/context7/github/sequentialthinking/aws-mcp-server), `master-demo-single` has 1 (aws-mcp-server only).
- `kiro-cli mcp list`: `testing` agent loads `playwright` MCP successfully (alongside aws-mcp-server, chrome-devtools, context7). `web-builder` loads `playwright` alongside its 7 other MCP servers.
- `steering/aws-standards.md`: zero E2E references (correct — it's CDK/Lambda focused, E2E rules live in `development-workflow.md`).
- README already has a `[Releases](https://github.com/seandkendall/kiro-config/releases)` link near the top (item 10 from the previous turn's recommendations was effectively done).

### Changed

- README: Skills 26 → 27, Custom (10) → Custom (11) with "Cypress-to-Playwright migration" added to the list.

## [0.12.0] - Cypress → Playwright migration

Full migration from Cypress to Playwright across the entire config. Decisions confirmed with user:

- `data-cy` → `data-testid` everywhere (Playwright-native convention)
- MCP only (no separate `@playwright/cli` skill)
- `@playwright/mcp@latest` (matches the daily-upgrade-deps rule)
- E2E expertise folded into the `testing` agent — dedicated `cypress` subagent deleted
- `@axe-core/playwright` library imports inside specs for accessibility (no separate a11y MCP)

### Removed

- **`agents/cypress.json` deleted** — E2E expertise moved into the `testing` agent
- **`prompts/cypress.md` deleted**
- **`@jprealini/cypress-mcp`** dropped from agent configs
- **`@browsermcp/mcp`** dropped from `testing` agent (replaced by `@playwright/mcp`)
- All `data-cy` selector references across steering / skills / README

### Added

- **`@playwright/mcp@latest`** added to `testing` agent with flags `--headless --isolated --caps=testing,storage,devtools` (Microsoft official Playwright MCP, 4.8M weekly downloads, 33.3k stars, no API key needed)
- **`@playwright/mcp@latest`** added to `web-builder` agent with `--headless --isolated`
- New "Playwright E2E Standards" section in `steering/development-workflow.md` covering: `data-testid` selectors via `page.getByTestId()`, `storageState` programmatic auth, `expect.poll()` and `page.waitForResponse()` waits (never `page.waitForTimeout`), `playwright.config.ts` baseURL + fullyParallel, `playwright-coverage` / `monocart-coverage-reports` for coverage, `@axe-core/playwright` for a11y, `--isolated` flag for parallel MCP browser sessions
- "Playwright E2E Issues" section in `steering/troubleshooting.md` with concrete recipes: `storageState` not loading, flake on CI, `page.route()` not matching, replacing `page.waitForTimeout`

### Changed

- **`testing` agent prompt** — owns ALL E2E work via Playwright. Drops the previous "delegate Cypress E2E to cypress subagent" delegation language.
- **`master.json` welcomeMessage** — "14 specialists" → "13 specialists" (cypress removed)
- **`master.json` / `ai-builder.json` / `web-builder.json` subagent rosters** — `cypress` removed from `availableAgents` and `trustedAgents`
- **`prompts/master.md`** — subagent list, parallel-chain workflow example, "Build me an app" workflow, "Write E2E tests" workflow all updated
- **`prompts/web-builder.md`, `ai-builder.md`, `reinvent.md`, `shopify.md`, `frontend.md`** — delegation paragraphs scrubbed of cypress, replaced with `testing` for E2E
- **`prompts/master-demo.md`, `master-demo-single.md`** — NEVER lists scrubbed of "Cypress" name; rules unchanged (still forbid all browser testing)
- **`prompts/accounting.md`** (local-only) — same treatment for consistency
- **`skills/testing-patterns.md`** — Cypress Quick Reference → Playwright Quick Reference (`page.getByTestId()`, `tests/e2e/*.spec.ts`, `tests/e2e/pages/*.ts`)
- **`skills/react-frontend-patterns.md`** — full `data-cy Selectors (MANDATORY — for Cypress)` section rewritten as `data-testid Selectors (MANDATORY — for Playwright)`. Naming pattern, table, rules, and code-review-enforcement language all updated.
- **`skills/gitignore.template`** — `cypress/screenshots/`, `cypress/videos/`, `cypress/downloads/` replaced with `test-results/`, `playwright-report/`, `playwright/.cache/`
- **`skills/mcp-tool-discovery.md`** — Cypress selector example → Playwright `generate_locator` MCP tool
- **`skills/deploy-on-aws.md`** — Pre-deployment quality gate: "Cypress E2E (target 100%)" → "Playwright E2E (target 100%)"
- **`steering/structure.md`** — directory layout `cypress/{e2e,pages,support,fixtures}/*.cy.ts` → `tests/e2e/{pages,fixtures}/*.spec.ts`
- **`steering/accessibility-standards.md`** — "Test in Cypress E2E" → "Test in Playwright E2E"
- **`steering/post-task-recommendations.md`** — Testing gaps recommendation updated
- **`steering/AGENTS.md`** — testing row updated, cypress row deleted from subagent table
- **`steering/tech.md`** — Testing tools list: Cypress (E2E) → Playwright (E2E with data-testid selectors)
- **README.md** — cypress row deleted from agent table, testing description updated, agent count 17 → 16, AWS MCP "All 17 agents" → "All 16"

### Counts after migration

- **Agents**: 16 (was 17)
- **Master subagent roster**: 13 (was 14)
- **Web-builder subagent roster**: 10 (was 11)
- **AI-builder subagent roster**: 9 (was 10)
- **Cypress references in non-CHANGELOG tracked files**: 0 (verified via grep)
- **`data-cy` references in tracked files**: 0 (verified via grep)

### Why

Microsoft's `@playwright/mcp` is the canonical browser-automation MCP in 2026 and is maintained by the Playwright core team. The official toolkit covers everything we used Cypress for plus capabilities Cypress doesn't have (multiple browsers including webkit/firefox, Playwright tracing, video recording, accessibility-tree-based interaction, request route mocking, `storageState` auth). The `cypress` subagent was a single-framework specialist; folding E2E into `testing` reduces agent count and makes the migration future-proof.

## [0.11.6] - Settings drift defenses + security email templates

### Added

- **`steering/development-workflow.md`** — two new MANDATORY rules:
  - **Settings Change Confirmation** — when `git add -A` would sweep up a `settings/cli.json` (or `agents/*.json`) change Kiro CLI silently mutated, surface the diff in your response BEFORE committing and ask the user. Never auto-revert. The user may have intentionally changed the setting outside this session.
  - **Stage Specific Files** — for narrow-scope changes, prefer `git add <files>` over `git add -A`. Three real stowaways have been caught in this project's history (`settings/survey_state.json`, two `chat.greeting.enabled` flips). Defensive default is to stage only what was intentionally changed.
- **`validate.sh` Step 5: Settings drift check** — soft warning (doesn't block) when `settings/cli.json` or `agents/*.json` has uncommitted changes. Surfaces the diff with revert instructions and a reminder to use `git add <specific-file>`.
- **`skills/email-templates/login-new-device.html`** + **`.txt`** (123 + 21 lines) — informational email when a user signs in from a new device or location. Sign-in details box (device / approximate location / time / IP), single CTA "This wasn't me" that links to the lock-account flow.
- **`skills/email-templates/security-alert.html`** + **`.txt`** (153 + 30 lines) — urgent email for the Cognito `AccountTakeOverNotification` trigger source OR when your own risk engine flags suspicious activity (impossible-travel velocity, brute-force, credential stuffing). Red banner, hard-coded warning color (NOT brand color — never green/blue for alerts), prominent "Lock my account" CTA, numbered recovery steps.
- **`README.md`** Configuration section — `chat.greeting.enabled: true` added to the documented defaults so setup is reproducible across machines.

### Changed

- **`chat.greeting.enabled = true`** is now the intentional default (previous session had it as false; user confirmed they want it on).

### Decisions documented

- **Master-demo greeting propagation skipped.** `chat.greeting.enabled` is a CLI-global setting in `settings/cli.json`, not a per-agent setting. Every agent (master, master-demo, master-demo-single, etc.) inherits the global value. No per-agent override is needed or possible.

## [0.11.5] - Email starter templates + Cognito migration runbook

### Added

- **`skills/email-templates/verification.html`** (106 lines) — brand-matched verification code email with prominent monospace code display. Used for Cognito SignUp / ResendCode / VerifyUserAttribute / UpdateUserAttribute trigger sources.
- **`skills/email-templates/password-reset.html`** (117 lines) — brand-matched password reset email with code display + CTA button to the reset page. Used for Cognito ForgotPassword.
- **`skills/email-templates/{welcome,verification,password-reset}.txt`** — plain-text companions for the three HTML templates. Hand-authored for readable plain-text rendering (not auto-converted from HTML).
- **`skills/cognito-email-migration.md`** (220 lines, `inclusion: auto`) — runbook for migrating an existing Cognito User Pool from default emails to a CustomEmailSender Lambda. Covers pre-flight, important caveat (one-way door — no fallback to default Cognito if Lambda fails), 8 migration steps, end-to-end test matrix, monitoring (CloudWatch errors, DLQ depth, SES bounce rate, synthetic test pass rate), and rollback plan.
- **`CONTRIBUTING.md`** — new "Email Templates" section. Contributors must follow `email-standards.md`, run new templates through the 20-item Email Checklist, place templates under `skills/email-templates/` with `.txt` companion, use the build pipeline (Premailer / Juice), and follow the migration runbook for existing User Pools.

### Verified

- AST compile check on `skills/email-templates/cognito-email-handler.py` — parses cleanly (210 lines, 7952 bytes)
- Audit: no agents currently load `skills/email-templates/*` as upfront resources. By design — templates are read-on-demand when relevant, not preloaded into every agent's context. The steering doc and rendering skill auto-include via keyword match.

### Decisions documented

- **`email-standards.md` stays as steering doc, NOT converted to a skill.** Considered moving to `skills/` for opt-in loading via `aws___retrieve_skill`, but kept as steering because: (a) the "always custom HTML, never defaults" rule is mandatory, not advisory; (b) agents won't think to retrieve a skill called "email-standards" — they'll assume they know how to send an email; (c) auto-trigger on keywords (signup, verification, password reset, Cognito email, SES, welcome, magic link) is the right behavior. Skills are for opt-in domain expertise; steering is for hard rules. Email defaults are a hard rule.

## [0.11.4] - Email standards: samples, render skill, checklist, decisions

### Added

- **`skills/email-templates/welcome.html`** (126 lines) — copy-paste-ready brand-matched welcome email template. Inline-styles-friendly source, `<table>` layout, preheader, single primary CTA, footer with mailing address + preferences link, dark-mode-safe. Placeholders: `{{ product_name }}`, `{{ logo_url }}`, `{{ primary_color }}`, `{{ accent_color }}`, `{{ user_name }}`, `{{ cta_url }}`, `{{ company_address }}`, `{{ unsubscribe_url }}`, `{{ support_email }}`.
- **`skills/email-templates/cognito-email-handler.py`** (210 lines) — sample Cognito `CustomEmailSender` Lambda. KMS-decrypts the verification code via the AWS Encryption SDK, renders Jinja2 templates, sends via SES with both HTML + plain-text parts (`multipart/alternative`). Maps all 7 Cognito trigger sources (SignUp, ResendCode, ForgotPassword, UpdateUserAttribute, VerifyUserAttribute, AdminCreateUser, AccountTakeOverNotification) to the right template + subject. Includes the CDK wiring as a reference comment block.
- **`skills/email-template-rendering.md`** (196 lines) — companion skill covering the build pipeline: Premailer (Python) and Juice (Node) for CSS inlining, plain-text fallback authoring, local preview workflow, cross-client testing options (Litmus / Email on Acid / Mailtrap), anti-patterns. Wires into `deploy.sh` as a pre-deploy step.
- **Email Checklist (20 items)** added to `steering/email-standards.md` — runs through every requirement before go-live: no defaults, no emojis, brand match, subject under 50 chars, preheader, single CTA, touch targets, inline CSS, plain-text alternative, web-safe fonts, alt text, color contrast, physical address, unsubscribe link, From-domain verified, cross-client preview, dark-mode, no `<script>`, subject+preheader read sensibly, real test send.
- **Templating Engines Comparison table** added to `steering/email-standards.md` — Jinja2 / Mustache / MJML / SES TemplateData with decision rules: Cognito-driven emails → Jinja2 in CustomEmailSender Lambda; app-driven transactional → Jinja2 OR pre-registered SES `CfnTemplate`; marketing → MJML compiled at build time.

### Audit results (no fixes needed)

- `prompts/` — zero references to "default Cognito email", Hosted UI defaults, or default SES templates
- `skills/amazon-bedrock/`, `skills/aws-serverless/` — no email-related guidance that conflicts with the new standards
- All existing agents will pick up the new rules through the auto-included `email-standards.md`

### Decisions documented

- **`inclusion: auto` retained** for `email-standards.md` (NOT switched to `always`). Most sessions never touch email — frontend component work, infrastructure tweaks, debugging. Loading 158 lines into every session is context bloat. The rich keyword list (email, verification, password reset, Cognito email, SES, welcome, magic link, etc.) reliably triggers when email work actually comes up.
- **No dedicated `email-builder` subagent.** Adding a 23rd agent for email construction would over-fragment the roster. Email work always comes up inside a broader build (Cognito flow → `serverless`, marketing flow → `web-builder`, AI notification → `ai-builder`). The steering doc + sample template + Lambda handler + render skill already give those agents everything they need.

## [0.11.3] - Email standards

### Added

- **`steering/email-standards.md`** (158 lines, `inclusion: auto`) — every user-facing transactional email this system sends MUST be a custom, brand-matched HTML email. No defaults, no emojis, full color, mobile-responsive, with plain-text fallback.
  - **Banned**: default Cognito verification email, default SES Welcome template, default Amplify Auth emails, plain-text-only when HTML is appropriate, emojis (subject line / preview / body), generic third-party templates without brand customization, external stylesheets (most clients strip `<link>`/`<style>`)
  - **Required visual**: brand match (logo / palette / typography / voice), full color, mobile single-column max-600px, inline CSS, touch-target buttons (44x44 min), one primary CTA per email
  - **Required technical**: `multipart/alternative` (HTML + plain text), web-safe fonts, absolute image URLs with `alt` text, no background images (Outlook strips them), cross-client rendering tests (Gmail / Outlook / Apple Mail / dark mode)
  - **Compliance**: physical mailing address footer (CAN-SPAM / CASL), unsubscribe / preferences link, From-domain verification (SPF + DKIM + DMARC)
  - **AWS implementation**: Cognito `CustomEmailSender` Lambda trigger with KMS-decrypted code; SES `CfnTemplate` for non-Cognito emails (welcome, billing, notifications)
  - **File layout**: `emails/{welcome,verification,password-reset,login-new-device}.{html,txt}` + `partials/header.html` + `partials/footer.html` + `styles.css` (inlined at build)
  - **Cross-references**: `accessibility-standards.md` (WCAG color contrast), `aws-standards.md` (Cognito custom UI rule), `security-policies.md` (SES API key management)
- **`steering/aws-standards.md`** Cognito section — new "Custom Cognito Emails (MANDATORY)" sub-rule that bans default Cognito verification, password-reset, and MFA emails. Points to `email-standards.md` for the full rule.

### Why

The base steering already mandated custom Cognito UI (login, registration, password reset pages) but said nothing about the emails Cognito sends. Default Cognito emails ("Your verification code is XXXXXX" with no styling) ship plain text from `no-reply@verificationemail.com` — that breaks the visual continuity the custom UI works hard to establish. Email is also a touchpoint where most teams default-to-default, so codifying it as a steering rule is high-leverage.

## [0.11.2] - master-demo-single agent

### Added

- **`master-demo-single` agent** — single-agent variant of `master-demo` for demos that benefit from one continuous thread of work rather than parallel orchestration. Same hard scope as `master-demo` (no UI, WAF, Route53/custom domains, AppRegistry, Powertools, X-Ray, cdk-nag, Kiro Specs, CI/CD) but with key simplifications:
  - **No subagents.** This agent does everything itself — write CDK, write Lambda handlers, deploy via `./deploy.sh -y`, verify endpoints + CORS. The whole demo is one linear flow.
  - **Only `aws-mcp-server`** (the AWS Agent Toolkit's core MCP). No `github`, no `web-search`, no `context7`, no `sequentialthinking`. Lean on purpose.
  - **`aws-serverless` skill bundle as primary reference** — covers Lambda configuration, API Gateway debugging, Step Functions, EventBridge, event source mappings, cold starts, deployment with SAM/CDK, troubleshooting.
  - Uses the v0.11.0 `deploy.sh` contract with `-y` for auto-confirm.
  - Keyboard shortcut: `ctrl+7`.
- README agent table updated: 16 → 17 agents
- AWS MCP Server count: "All 16 agents" → "All 17 agents"
- AGENTS.md "When to Use Which Agent" updated with `master-demo-single` and routing guidance ("use when the demo benefits from one continuous thread of work rather than parallel orchestration")

### When to use which demo agent

| Agent                         | Best for                                                                                                 |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| `master-demo` (shift+m)       | Demos showing how subagents fan out in parallel — the orchestration IS the show                          |
| `master-demo-single` (ctrl+7) | Demos where the audience benefits from one focused, linear thread — no orchestration overhead to explain |

Both follow identical hard rules; the only difference is whether subagents are involved.

## [0.11.1] - Time-budget removal + deploy.sh template hardening

### Removed

- **All time budgets from `master-demo`** — the previous "10-MINUTE BUDGET" framing in `prompts/master-demo.md` directly violated the existing **"No Time Estimates (MANDATORY)"** rule in `steering/development-workflow.md`. Renamed `SPEED RULES` → `EFFICIENCY RULES`. Dropped every "10 minutes / 10-minute / under N minutes" reference. The same 9 efficiency tradeoffs (skip Specs, HTTP API, PAY_PER_REQUEST, single stack, no Layers, etc.) are kept — they're concrete tradeoffs, not time estimates.
- Added an explicit `NO TIME ESTIMATES` reminder block in `master-demo.md` cross-referencing `development-workflow.md`. If asked "how long?", respond with scope (number of stacks, services, resources) — never time.
- `master-demo.json` `welcomeMessage` updated: dropped "<10min budget", trimmed to 175 chars.

### Added

- **`skills/gitignore.template`** (96 lines) — copy-paste-ready `.gitignore` for AWS CDK + React projects deployed via `deploy.sh`. Includes `.deploy-state.json` (per-profile state file from the v0.11.0 contract), all `.env*` patterns, AWS credential files, CDK output dirs, Python/Node/Vite caches, Cypress artifacts, editor/OS junk.
- **`ai-builder.md`** — explicit deploy.sh contract reference added to the AgentCore app-build orchestration section. Lists the 5 flags, points to `.deploy-state.json` for per-profile state, references `skills/deploy.sh.template`. (master.md and web-builder.md don't deploy directly — they delegate to `serverless` which inherits the contract from `aws-standards.md`.)

### Changed

- **`master-demo` prompt — explicit `-y` flag usage in deployment flow.** All `./deploy.sh` invocations now show `./deploy.sh -y` (deploy) and `./deploy.sh --delete -y` (teardown), making the demo's auto-confirm pattern explicit.
- **`skills/deploy.sh.template` Route53 cleanup made concrete.** The previous `# TODO: Route53 record cleanup` placeholder is replaced with a working implementation:
  - Walks up the domain levels to find the hosted zone (e.g., `d1.app.example.com` → `app.example.com` → `example.com`)
  - Lists any `RecordSets` whose Name matches the deployed domain (these are orphans `cdk destroy` left behind)
  - Asks the user to confirm before deletion (skipped under `-y`)
  - Builds a Route53 change-batch with `DELETE` actions and submits via `change-resource-record-sets`
  - **Never deletes the hosted zone itself** — zones are treated as shared infra across projects in the account

## [0.11.0] - deploy.sh full contract + Claude Opus 4.8

### Changed

- **Default model bumped: `claude-opus-4.7` → `claude-opus-4.8`**
  - `settings/cli.json` `chat.defaultModel` updated
  - `steering/AGENTS.md` "Adaptive Thinking" section updated
  - `steering/tech.md` "Kiro CLI Tooling" section updated
  - README "Configuration" section updated
  - The historical `4.6 → 4.7` migration note in `skills/amazon-bedrock/references/model-migration.md` is kept intentionally — it documents prior migration history, not the current default

### Added

- **Full `deploy.sh` contract** specified in `steering/aws-standards.md`. Every project's `deploy.sh` MUST follow it:
  - **Flags**: `--profile <name>` (defaults to `default`), `--domain <fqdn>`, `--delete`, `-y`/`--yes`, `-h`/`--help`
  - **Per-profile state** in `.deploy-state.json` (gitignored). When `--domain` is passed, the value is saved keyed by AWS profile. Subsequent runs without `--domain` recall the saved value for the current profile.
  - **Deep-cleanup on `--delete`**: empties + deletes S3 buckets, deletes CloudWatch log groups, removes Route53 records the stack added (without deleting the zone), deletes ACM certificates the stack created, deletes SQS/SNS/EventBridge/ECR resources owned by the stack, detaches and deletes IAM roles + policies. Discovery is by tag (`project=<name>`), never by name prefix.
  - **`-y` auto-confirm flag**: skips every interactive prompt (intended for CI-like usage and `master-demo`)
  - **Multi-project safety in shared AWS accounts**: discovery by tag (NOT by name prefix), surgical Route53 record deletion (never delete the hosted zone if shared), pre-flight resource list shown before deletion, `CDKToolkit` bootstrap stack is NEVER destroyed by `deploy.sh --delete`
- **Reference template**: `skills/deploy.sh.template` fully rewritten (330 lines) implementing the contract end-to-end
- **`skills/deploy-on-aws.md`** updated to summarize the contract and link back to the canonical rule in `steering/aws-standards.md`

### Why

The previous `deploy.sh` contract was minimal (`--profile`, `--delete`). Three real-world pain points led to this expansion:

1. **Manual domain re-typing**: every redeploy required passing `--domain` again. Now saved per-profile in `.deploy-state.json`.
2. **Orphaned resources after `cdk destroy`**: non-empty S3 buckets, retained CloudWatch log groups, lingering ACM certs. Now `--delete` deep-cleans by tag.
3. **Cross-project blast radius in shared AWS accounts**: deleting a stack could nuke Route53 records or ACM certs owned by sibling projects. Now discovery is tag-based and the `CDKToolkit` is explicitly excluded from `--delete`.

## [0.10.3] - master-demo speed optimization

### Changed

- **`master-demo` rebuilt for speed** — total time from "user describes the build" to "all endpoints tested and CORS verified" must fit under **10 minutes**. New `SPEED RULES (10-MINUTE BUDGET)` section in the prompt with 9 concrete speedups in priority order:
  - Skip Kiro Specs phase (replace with 3-bullet inline plan; biggest win)
  - HTTP API instead of REST API (faster deploy, native CORS, lower cold start)
  - DynamoDB PAY_PER_REQUEST (no provisioned capacity)
  - Single stack, no nested stacks
  - Inline Lambda code or single-file `PythonFunction`, no Lambda Layers
  - `cdk deploy --require-approval never`, skip `cdk diff`
  - Unit tests off the critical path (post-deploy endpoint sweep IS the test suite)
  - Plain `logging.getLogger`, not Lambda Powertools
  - Skip cdk-nag during demo, run after if asked
- Expanded NEVER list with 8 new explicit overrides of base steering rules: AppRegistry, Powertools, X-Ray, DLQ + idempotency, Layers, resource tagging, Cognito/auth, request models, cdk-nag, Kiro Specs. Each entry calls out the base rule it's overriding and why master-demo's "demo only" scope authorizes the override.
- `welcomeMessage` updated to 185 chars and signals speed mode: "master-demo ready. AWS serverless, <10min budget. No UI/WAF/AppRegistry/Powertools/X-Ray/cdk-nag/Kiro-Specs..."

### Why

Live demos compete for attention. A 30-minute build loses the room. The 10-minute budget forces decisions about which production-grade rules add demo-time noise (cdk-nag, AppRegistry, Powertools observability stack, full Kiro Spec phase) and which stay (CORS verification, endpoint testing, default account, no WAF/Route53/custom domains). The base steering docs still apply to production projects — master-demo's overrides are scoped to the agent itself.

## [0.10.2] - AWS Support Case Ban

### Added

- **`AWS Support Case Ban (STRICT)`** — new section in `steering/post-task-recommendations.md` alongside the existing CI/CD and Git Hook bans. Hard rule: agents NEVER auto-open AWS Support cases (technical, account/billing, service-limit-increase) or call Service Quotas API for quota requests without explicit user instruction. When a quota wall is hit, surface the limit and recommend the user open the case manually.
- Mirror cross-reference added to `steering/aws-agent-toolkit.md` ("AWS Support API Guard" section) since `aws-mcp-server` exposes the AWS Support API. The MCP-over-CLI rule does NOT authorize unattended case creation.

## [0.10.1] - master-demo agent

### Added

- **`master-demo` orchestrator agent** for live serverless backend demos. Showcases parallel subagent execution as a teaching tool. Hard scope:
  - ALWAYS: AWS serverless, default AWS account, post-deploy endpoint sweep, CORS verification (preflight + actual), parallel subagents, OpenAPI 3 native, can inspect public frontend pages to design matching backends
  - NEVER: UI code, browser testing (Cypress/Playwright), WAF, Route53/custom domains/ACM certs, ServiceCatalog AppRegistry (explicit override of the base aws-standards rule — demos skip it), CI/CD pipelines
- 9 subagents available: `serverless` (primary), `architect`, `data`, `security`, `testing`, `devops`, `docs`, `research`, `ai-builder`
- Keyboard shortcut: `shift+m`
- 5 MCP servers (mirror of master): `aws-mcp-server`, `github`, `web-search`, `context7`, `sequentialthinking`
- README agent table updated: 15 → 16 agents
- AWS MCP Server count: "All 15 agents" → "All 16 agents"
- AGENTS.md "When to Use Which Agent" updated with `master-demo`

## [0.10.0] - First public release

A multi-agent AWS development environment for the Kiro CLI. Includes a master orchestrator that delegates to 12 specialist subagents, 16 always-available steering docs, 24 skills covering AWS patterns and custom workflows, and a curated MCP server stack centered on the AWS Agent Toolkit.

### Agents (15)

- **Orchestrators** — `master` (default, ctrl+1), `web-builder`, `ai-builder`
- **Specialists** — `serverless`, `frontend`, `testing`, `cypress`, `architect`, `data`, `devops`, `security`, `docs`, `image-gen`, `research`, `google-workspace`

The master agent runs up to 4 subagents in parallel and returns consolidated results. `web-builder` and `ai-builder` are themselves orchestrators that delegate frontend/backend/AI work to the relevant specialists.

### Steering Docs (16, always-loaded)

Accessibility, AGENTS, API standards, AWS Agent Toolkit, AWS standards, development workflow, error handling, Kiro CLI troubleshooting, MCP server preference, performance optimization, post-task recommendations, product, Python standards, security policies, session continuity, structure, tech, troubleshooting — plus the meta-rule `personal-rules-protocol` that drives self-evolving local rules.

### Skills (24)

- **Custom (8)** — AWS serverless patterns, CDK infrastructure, React frontend, testing patterns, deploy-on-aws, AWS architecture diagrams (draw.io XML), AWS diagram PNG (awsdac), personal rules management
- **AWS Agent Toolkit (16)** — Lambda+API GW, Lambda+DynamoDB, debugging timeouts, CloudFront routing, serverless decision guide, S3 security, IAM, Secrets Manager, observability, CloudWatch alarms, app failure troubleshooting, Bedrock, billing/cost, CloudFormation, messaging/streaming, MCP tool discovery

### MCP Servers

- `aws-mcp-server` (Agent Toolkit for AWS) — single managed entry point for all AWS interactions on every agent
- `github` — GitHub API operations (mandated over `gh` CLI)
- `context7` — live library docs
- `playwright`, `chrome-devtools`, `browser-lens` — browser automation and CSS debugging
- `shadcn`, `21st-dev-magic`, `figma-framelink` — UI generation and design-to-code
- `sequentialthinking` — structured reasoning chains
- `bedrock-image-mcp-server` — image generation via Nova Canvas + SD 3.5
- `duckduckgo` — privacy-first web search
- `google-drive` — read-only Google Workspace access

### Self-Evolving Personal Rules

When the user states a preference using "always / never / from now on / I prefer …" OR repeats a preference 2+ times in a session, the agent proposes saving it as a `personal-<topic>.md` steering doc. Personal rules:

- Are gitignored (`steering/personal-*.md`, `agents/personal-*.json`, `prompts/personal-*.md`)
- ALWAYS win over base rules on the user's machine
- Have built-in PII/credentials guard (refuses to save AWS keys, API tokens, emails, phone numbers, JDBC URLs, private keys)
- Surface stale entries (>60 days) for review

### Tooling Standards

- **CDK in Python only** — never TypeScript for infrastructure
- **TypeScript only for React frontends**
- **Python 3.14** Lambda runtime across all agents and templates
- **`deploy.sh` is the only deployment method** — no CI/CD pipelines, no git hooks (both explicitly banned)
- **MCP-over-CLI rule** — github MCP for github.com operations (never `gh`); `aws-mcp-server` for AWS (never bare `aws` CLI)
- **`./validate.sh`** — local pre-push validation. Validates all 15+ agent JSONs, JSON syntax, bash syntax, and gitignore privacy guard.
- **Documentation Sync rule** — `CHANGELOG.md` and `README.md` updates ship in the same commit as the change that affects them

### Default Configuration

- `chat.defaultAgent`: `master`
- `chat.defaultModel`: `claude-opus-4.8`
- `chat.enableSubagent`: `true`
- `chat.enableThinking`: `true`
- `chat.enableTodoList`: `true`
- `toolSearch.enabled`: `true`
