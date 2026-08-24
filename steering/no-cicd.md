---
inclusion: always
name: no-cicd
description: This project never implements CI/CD. Never propose GitHub Actions, CodePipeline, CodeBuild, Jenkins, GitLab CI, or any automated pipeline or git hook; local validate.sh + deploy.sh gates ARE the pipeline.
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
