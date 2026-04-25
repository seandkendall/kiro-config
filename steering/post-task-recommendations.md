---
inclusion: auto
name: post-task-recommendations
description: Mandatory post-task recommendation format with priority-sorted next steps. Use when completing any code, infrastructure, or system-building task.
---

# Post-Task Recommendations (MANDATORY)

## When to Provide Recommendations

After completing ANY code, infrastructure, or system-building task — when you are ready for the user to provide next steps — you MUST provide a numbered list of **at least 10 recommendations**.

This applies to every task where code was written, modified, deployed, or reviewed.

## Recommendation Categories (in priority order)

Recommendations MUST be sorted from highest to lowest priority. Non-feature items always come before new features:

1. **Critical fixes** — bugs, security vulnerabilities, broken functionality
2. **Linting & compilation** — eslint errors/warnings, pylint/flake8 issues, type errors
3. **Code cleanup** — dead code removal, unused imports, naming consistency
4. **Hardening** — input validation, error handling, edge cases, defensive coding
5. **Security** — IAM tightening, secrets management, OWASP prevention
6. **Performance** — cold starts, bundle size, query optimization, caching
7. **Cost optimization** — right-sizing Lambda memory, DynamoDB capacity, CloudFront caching
8. **Testing gaps** — missing unit tests, uncovered branches, E2E coverage
9. **Documentation** — missing docstrings, README updates, API spec gaps
10. **New features & enhancements** — ALWAYS listed last, after all of the above

## Format

```
## Recommended Next Steps

1. [highest priority item]
2. ...
...
10. [lowest priority / new feature suggestion]
```

## CI/CD Ban (STRICT)

- **NEVER** recommend CI/CD pipelines, GitHub Actions, GitLab CI, CodePipeline, or any continuous integration/deployment system
- **NEVER** suggest setting up automated build/deploy pipelines
- The ONLY deployment method is the `deploy.sh` script — always recommend and enforce this
- If a user explicitly asks for CI/CD, only then may you help implement it
- This rule applies to ALL agents, ALL subagents, and ALL sessions
