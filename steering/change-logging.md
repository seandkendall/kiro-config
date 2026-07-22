---
inclusion: always
name: change-logging
description: "Mandatory per-project change log. Every project MUST have a CHANGES.md at its root. Before returning to the user after any set of changes, append a timestamped, round-numbered entry (date/time header + bullet list) so the file renders cleanly on GitHub. Use whenever you create, modify, or delete files in a project."
---

# Change Logging (MANDATORY)

Every project MUST maintain a `CHANGES.md` file at the **root of the project directory**. It is a running, append-only log of every change-set an AI agent makes to that project.

This applies to **ALL agents, ALL subagents, and ALL sessions**, in **ANY project** — not just this repo.

## The Rule

After you complete a set of changes (file creations, edits, deletions, config changes, scaffolds, refactors, etc.) and **before you return to the user with your summary / next steps**, you MUST append a new entry to `CHANGES.md`.

- If `CHANGES.md` does not exist at the project root, **create it** (see "First-time file" below), then add the first entry as `Round 1`.
- If it exists, **append** the new entry — never overwrite, never rewrite prior rounds.
- Write the entry as the **last action before responding** to the user, so the log always reflects the work just done.

> This is distinct from a `CHANGELOG.md` (Keep a Changelog / release-oriented). A project may have both: `CHANGELOG.md` tracks released, human-curated, version-grouped notes; `CHANGES.md` is the chronological, round-by-round record of agent activity. Maintaining one does not excuse maintaining the other.

## Round Numbering

- A "round" = one set of changes made in one turn before handing back to the user.
- Determine the next round number by reading the **existing** `CHANGES.md` and finding the highest `Round N` header, then incrementing it (`N + 1`).
- A brand-new `CHANGES.md` starts at `Round 1`.
- Round numbers are **monotonic and never reused**, even across sessions, agents, or days. They are independent of dates — multiple rounds can share a date; a single round never spans dates.

## Timestamp

- Use the current local time from the session context (the `Current time:` entry), including the timezone offset — e.g. `2026-06-16 18:25:28 -04:00`.
- If no current time is available for the turn, omit the time but still include the date and round number — never fabricate a timestamp.

## Entry Format (GitHub-friendly)

Each entry is a level-2 heading followed by a bullet list. This renders as a clean, scannable section list on GitHub:

```markdown
## Round <N> — <YYYY-MM-DD HH:MM:SS ±HH:MM>

- <Concise description of a change, referencing the file/path touched>
- <Another change>
- <Another change>
```

Rules for the body:

- One bullet per discrete change. Lead with the action verb (Added / Updated / Removed / Fixed / Renamed / Moved).
- Reference the concrete file path, function, or component when relevant (e.g., ``Updated `src/auth/login.ts` to validate JWT expiry``).
- Keep bullets to a single line where possible; use nested bullets only for sub-items of one change.
- Use backticks for file paths, commands, and identifiers so they render as inline code.
- No emojis (consistent with this config's tone).
- Do NOT include time estimates (consistent with `development-workflow.md`).
- Separate consecutive rounds with a blank line. Do not add horizontal rules between rounds — the `##` headings provide enough visual separation on GitHub.

## First-time File

When creating `CHANGES.md` for the first time, start it with a title and a one-line description, then the first round:

```markdown
# Changes

A chronological log of change-sets made to this project. Each round is one set of
changes recorded before handing back to the user. Newest rounds are appended to the bottom.

## Round 1 — 2026-06-16 18:25:28 -04:00

- Added initial project scaffold (`package.json`, `tsconfig.json`, `src/index.ts`)
- Configured Vite build with React + TypeScript
```

## Ordering

- Append newest rounds to the **bottom** of the file (chronological top-to-bottom). This keeps round numbers in reading order and makes `git diff` show new entries as pure additions.

## What Counts as a Change-Set

Record a round whenever you:

- Create, modify, delete, move, or rename project files
- Change configuration, dependencies, or infrastructure code
- Scaffold a feature, fix a bug, or refactor code

You do NOT need to record a round for read-only / investigative turns where no files changed (answering a question, explaining code, running a non-mutating analysis). If nothing in the project changed, skip the log for that turn.

## Interaction with Other Rules

- The `CHANGES.md` write happens **before** the "Recommended Next Steps" section required by `post-task-recommendations.md` — log first, then respond.
- This rule complements the "Documentation Sync" rule in `development-workflow.md` (which governs `CHANGELOG.md` + `README.md` for this specific config repo). When working inside a repo that has its own `CHANGELOG.md`, update both: the project's `CHANGELOG.md` per its convention AND `CHANGES.md` per this rule.
