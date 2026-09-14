---
inclusion: auto
name: docker-standards
description: 'Docker cleanup and disk-space hygiene for projects using Docker/Docker Compose. Use when working on a Dockerized project, or when the user asks about disk usage, cleaning up Docker, freeing space, or Docker running slow/full.'
---

# Docker Standards

## Disk Space Cleanup (Suggest, Don't Auto-Run)

When working on a project that uses Docker (a `Dockerfile`, `docker-compose.yml`/`.yaml`, or `Containerfile` is present), it's useful to periodically clean up unused Docker resources to keep the machine's disk usage under control.

**The cleanup command:**

```bash
docker system prune -a --volumes
```

This removes:

- All stopped containers
- All networks not used by at least one container
- All images without at least one referencing container (not just dangling ones, because of `-a`)
- All volumes not used by at least one container (because of `--volumes`)
- The build cache

**This is destructive and not easily reversible** — `--volumes` in particular can delete real data (local databases, uploaded files, seeded dev data) if it lives in a volume not currently attached to a running container. Treat it like any other destructive operation under this config's safety guardrails:

- **Do not run this proactively or on a schedule.** Only suggest it when disk cleanup is relevant (the user asks about disk space, Docker running slow, "clean up docker," or after finishing Docker-heavy work where cleanup is a natural next step) — and even then, propose it rather than running it unprompted.
- **Before running it, list what would be affected** — `docker system df` (summary) and/or `docker volume ls` — so the user can see named volumes before they're gone. Flag any volume names that look like they hold real data (e.g., `*_db_data`, `*_pgdata`, `*_uploads`) explicitly.
- **Get explicit confirmation before running it**, same as any other destructive/hard-to-reverse action (see `safety_guardrails`). Briefly state what will be removed and that volumes not attached to a running container will be deleted.
- **Never combine this with other automated hooks or CI steps** — consistent with `no-cicd.md`, this is a manual, deliberate cleanup action the user runs (or approves) themselves, not something wired into `deploy.sh` or any automated pipeline.

## When to Suggest It

Good moments to mention this command (not run it):

- The user mentions disk space, laptop storage, or Docker Desktop/daemon disk usage
- A long Docker-heavy session (many image rebuilds, `docker-compose up` cycles) has left a lot of dangling images/containers behind
- The user explicitly asks how to "clean up Docker" or similar

If the user wants a less destructive first pass, `docker system prune` (no `-a`, no `--volumes`) only removes stopped containers, dangling images, and unused networks — no volumes touched. Offer that as the safer alternative when the user seems unsure how aggressive to be.
