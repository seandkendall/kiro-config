---
inclusion: always
name: development-workflow
description: "Mandatory core development rules: no time estimates, timestamped output, Kiro Specs before code, TODO lists, chain of thought, file modification in-place (no _v2/_new files), rule acknowledgment, response format with post-task recommendations, documentation sync, settings-change confirmation, stage-specific git adds. Use for every code/build/fix task."
---

# Development Workflow (Core Rules)

> Build/test/lint detail (quality gates, Playwright standards, testing patterns, daily
> maintenance, code review checklist) lives in `development-quality-gates.md` (auto-loaded
> when building/testing/reviewing).

## Code Quality Core

**File Modification Rule** - When modifying existing code, ALWAYS edit files in-place. NEVER create duplicate files like `file_new.py`, `file_modified.py`, `file_v2.py`, `file_backup.py`, or `ClassName_updated.java` alongside the original. Check if a file exists before creating it — if it exists, modify it.

**Build before done** - All code MUST compile/build successfully before considering it complete. Zero errors, zero warnings, zero deprecation notices (full gate: `development-quality-gates.md`).

## Kiro Interaction Rules

**No Time Estimates (MANDATORY)** - Never provide time estimates:

- Do NOT estimate hours, days, weeks, story points, or sprint sizes for any task
- Do NOT say things like "this is 90-120 hours of work" or "this will take X days"
- Do NOT include effort sizing (small/medium/large) unless the user explicitly asks
- Just execute the work. Time estimates are unreliable for AI-assisted development and add noise
- If the user asks for complexity, respond with scope (number of files, dependencies, risks) — not time

**Timestamped Output (MANDATORY)** - Stamp your output with the current local time so the user can see WHEN each comment, decision, or status update was made:

- Use the current time provided in the session context (the `Current time:` context entry) — it carries the user's timezone offset (e.g., `2026-06-13T13:11:02-06:00`).
- Print a timestamp at the **start of every response**, and again before major status updates within a long-running response (e.g., before each phase of a multi-step task, before/after a long tool run, when reporting a result).
- Format: `[HH:MM:SS TZ]` or `[YYYY-MM-DD HH:MM:SS -06:00]` — keep it compact and include the timezone offset or abbreviation so it's unambiguous. Example: `[13:11:02 MDT] Starting the migration…`
- Apply this to feedback, reasoning/thinking narration, progress updates, and final summaries.
- This is NOT a time estimate — it's a wall-clock timestamp of when the comment was written. It does not conflict with the "No Time Estimates" rule above (which bans predicting how _long_ work will take). Printing the current time is always allowed and encouraged; predicting durations is still banned.
- If the session context does not include a current time for the turn, omit the timestamp rather than guessing — never fabricate a time.

**Kiro Specs (MANDATORY)** - Before writing ANY code:

- New features: Create a Kiro Feature Spec (requirements.md → design.md → tasks.md)
- Bug fixes: Create a Kiro Bugfix Spec (bugfix.md → design.md → tasks.md)
- Never skip the spec phase. Code without a spec will not be accepted.

**TODO List (MANDATORY)** - Always use the `todo_list` tool:

- Create a persistent TODO list for every multi-step task
- Mark tasks as completed immediately after finishing them
- Never work on multi-step tasks without an active TODO list

**Chain of Thought (MANDATORY)** - Always use the `thinking` tool:

- Before complex decisions, multi-step changes, or architectural choices
- Break problems down into steps before acting
- Document reasoning for non-obvious decisions

**Rule Acknowledgment** - When acting based on a steering rule:

- Print "Rule used: `filename.md` (ID)" at start of response
- For multiple rules: "Rule used: `file1.md` (ID1), `file2.md` (ID2)"
- Don't mention rules generically, only cite specific ones used

**Rule Checking** - Always review steering docs before:

- Using any tool
- Responding to requests
- Making code changes

**Response Format (MANDATORY)** - After completing any code/build/fix task, ALWAYS end with:

1. **Summary**: Brief description of what was done
2. **Tools & MCP Servers Used**: List every tool, MCP server, and subagent invoked
3. **Recommended Next Steps**: Follow the format in `post-task-recommendations.md` — split into "for the user" (optional) and "for the AI Agent" (mandatory, ≥10 items, sorted by priority)

**Documentation Sync (MANDATORY)** - When you make changes to this repo:

- **ALWAYS update `CHANGELOG.md`** with a new entry for the change. If a dated entry for today already exists, append to it; otherwise create a new one. Group entries under `### Added`, `### Changed`, `### Removed`, `### Fixed` as appropriate.
- **ALWAYS update `README.md`** when the change affects:
  - The agent table (additions, removals, renames)
  - The skills count or table
  - The MCP server table
  - Required environment variables
  - Prerequisites or installation steps
  - Configuration defaults (model, settings)
- Both updates happen in the SAME commit as the underlying change — do not defer to a separate commit
- This rule applies to ALL agents, ALL subagents, and ALL sessions

**Settings Change Confirmation (MANDATORY)** - Kiro CLI silently mutates `settings/cli.json` during normal use (e.g., it can flip `chat.greeting.enabled` between sessions). When `git add -A` would sweep up such a change:

- ALWAYS surface the diff in your response BEFORE committing
- ALWAYS ask the user whether the change is intentional, unless the change is clearly part of the current task (e.g., the user asked to bump the default model)
- NEVER auto-revert a settings change just because it wasn't explicitly requested — the user may have made the change deliberately outside this session. Surface, ask, then act on their answer.
- Prefer `git add <specific-file>` over `git add -A` when the task scope is narrow, to avoid sweeping up unrelated state mutations entirely
- This rule also applies to: `agents/*.json` (Kiro CLI may rewrite formatting on agent edits) and any other config files that the CLI itself manages

**Stage Specific Files (MANDATORY)** - For narrow-scope changes (one file, one feature), use `git add <files>` over `git add -A`. Three real stowaways have been caught in this project's history (`settings/survey_state.json`, two `chat.greeting.enabled` flips) — each was caused by `git add -A` sweeping in unrelated state. The defensive default is to stage only what you intentionally changed.
