---
inclusion: always
name: no-cicd
description: This project never implements CI/CD. Never propose GitHub Actions, CodePipeline, CodeBuild, Jenkins, GitLab CI, or any automated pipeline or git hook; local validate.sh + deploy.sh gates ARE the pipeline. Kiro CLI Workflows (user-triggered, local) are explicitly allowed and are not CI/CD.
---

# No CI/CD (ever)

- **Never propose or implement CI/CD** — no GitHub Actions, CodePipeline,
  CodeBuild, Jenkins, GitLab CI, pre-commit hooks, or any automated pipeline.
- Validation runs **locally**: a `validate.sh`-style gate plus the `deploy.sh`
  quality gate. Those ARE the pipeline.
- Do not add CI-only configuration (e.g. `retries` for flaky tests "in CI",
  `if: github.event_name` blocks, CI-specific env branches).
- Consequence to respect: with no CI to quarantine failures, a flaky test must be
  fixed at its root cause, not absorbed by retries.
- Do not recommend CI/CD in "next steps" or recommendation lists. If continuous
  validation is genuinely needed, the answer is extending `validate.sh` / `deploy.sh`,
  not adding a pipeline.

## Kiro Workflows are explicitly allowed (user opt-in, confirmed)

Kiro CLI **Workflows** (2.26.0, opt-in via `/settings` → Features → Workflows, run
with `/workflow run`) are NOT covered by the ban above and may be proposed or used.
The distinction: Workflows are a user-triggered, local execution aid inside the CLI
itself, not an externally-hosted automated pipeline that runs on every push without
a human in the loop. They don't quarantine flaky tests with retries, don't run on
`github.event_name`-style triggers, and don't replace `validate.sh`/`deploy.sh` as
the quality gate — they can call into those scripts, not substitute for them.
