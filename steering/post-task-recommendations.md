---
inclusion: auto
name: post-task-recommendations
description: Mandatory post-task recommendation format with user vs AI Agent split, priority sorting, and "Continue" interaction model. Use when completing any code, infrastructure, or system-building task.
---

# Post-Task Recommendations (MANDATORY)

After completing ANY code, infrastructure, or system-building task, you MUST end your response with a **"Recommended Next Steps"** section. This applies to every task where code was written, modified, deployed, or reviewed.

The section is split into two parts:

1. **Recommended Next Steps (for the user)** — OPTIONAL. Only include when there are real actions the user must take outside the agent (sign in to a console, add an API key, approve a request, run something interactively, make a business decision).
2. **Recommended Next Steps (for the AI Agent)** — MANDATORY. Always include. At minimum 10 items, more if needed. Sorted by priority. The user will reply with `Continue` to execute all items in order, or with specific item numbers (e.g., `Continue with 1, 3, 5`) to execute a subset.

## Format

```markdown
## Recommended Next Steps (for the user)

_Only include this section when one or more user actions are genuinely required. Skip it entirely otherwise._

1. [user-only action — e.g., "Add `FOO_API_KEY` to ~/.zshrc — get one at https://example.com"]
2. [user-only action — e.g., "Approve the IAM role change in the AWS Console for account 123456789012"]

---

## Recommended Next Steps (for the AI Agent)

Reply with `Continue` to execute all items in order, or specify item numbers (e.g., `Continue with 2, 5, 8`).

1. [highest-priority item — e.g., "Fix the failing `test_auth.py::test_passkey_register` test"]
2. [next priority — e.g., "Resolve the 3 ruff warnings in `cdk-backend/lambda/handlers/orders.py`"]
3. ...
4. [lowest-priority / new feature — e.g., "Add bulk-export endpoint for invoices"]
```

## Rules for "Recommended Next Steps (for the user)"

- **OMIT the section entirely** when there are no real user-only actions
- Use this section ONLY for actions the AI Agent CANNOT do on its own:
  - Adding/rotating API keys or credentials in a password manager or `~/.zshrc`
  - Granting permissions in the AWS Console (e.g., approving a service quota increase, accepting an organization invite)
  - Manual approvals (e.g., approving a code review request, approving a PR)
  - Business decisions that require the user's judgment
  - Hardware actions (e.g., plug in a YubiKey, restart your Mac)
- NEVER include items the AI Agent could complete autonomously — those go in the AI Agent list

## Rules for "Recommended Next Steps (for the AI Agent)"

- **MANDATORY** on every task completion — never omit
- **MINIMUM 10 items** — add more if more are warranted
- Each item must be **actionable by the AI Agent** without further user input (assume the user will type `Continue`)
- Each item must be **concrete and self-contained** — include the file path, function name, or specific change needed
- Sort by priority, highest first. Non-feature items always come before new features:
  1. **Critical fixes** — bugs, security vulnerabilities, broken functionality, failing tests
  2. **Linting & compilation** — ruff/eslint errors and warnings, pylint/flake8 issues, type errors, deprecation notices
  3. **Code cleanup** — dead code removal, unused imports, naming consistency, in-place edits to remove duplicate `_v2`/`_new` files
  4. **Hardening** — input validation, error handling, edge cases, defensive coding, idempotency
  5. **Security** — IAM tightening, secrets management, OWASP prevention, AWS managed KMS keys preferred
  6. **Performance** — cold starts, bundle size, query optimization, caching, X-Ray sampling
  7. **Cost optimization** — right-sizing Lambda memory, DynamoDB capacity, CloudFront caching, log retention
  8. **Testing gaps** — missing unit tests (target ≥90% coverage), uncovered branches, Cypress E2E coverage (target 100%)
  9. **Documentation** — missing docstrings, README updates, API spec gaps, ADRs
  10. **New features & enhancements** — ALWAYS listed last

## Continuation Behavior

When the user replies with `Continue` (or `continue`):

- Execute every item in the "for the AI Agent" list, in order
- If an item is no longer applicable (e.g., already fixed), skip it and note why
- After completing all items, produce a NEW "Recommended Next Steps" section reflecting the current state

When the user replies with `Continue with <numbers>` (e.g., `Continue with 2, 5, 8`):

- Execute ONLY those numbered items, in the order given
- Do NOT execute the other items
- After completing the chosen items, produce a NEW "Recommended Next Steps" section

When the user replies with anything else: treat their reply as a new instruction, not a continuation.

## CI/CD Ban (STRICT)

- **NEVER** recommend CI/CD pipelines, GitHub Actions, GitLab CI, CodePipeline, or any continuous integration/deployment system
- **NEVER** suggest setting up automated build/deploy pipelines
- The ONLY deployment method is the `deploy.sh` script — always recommend and enforce this
- If a user explicitly asks for CI/CD, only then may you help implement it
- This rule applies to ALL agents, ALL subagents, and ALL sessions

## Git Hook Ban (STRICT)

- **NEVER** recommend adding git hooks (pre-commit, pre-push, post-merge, etc.)
- **NEVER** suggest installing hook frameworks like `pre-commit`, `husky`, or `lefthook`
- **NEVER** suggest auto-running validators, linters, or formatters via hooks
- If a user explicitly asks for a git hook, only then may you help implement it
- This rule applies to ALL agents, ALL subagents, and ALL sessions
- Validation should be done manually by the user (e.g., `./test-import.sh`) or as part of the `deploy.sh` quality gate, never enforced through hooks
