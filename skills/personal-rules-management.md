---
name: personal-rules-management
description: List, edit, consolidate, and delete personal-*.md steering rules. Use when the user asks "what personal rules do I have", "remove my pastel rule", "merge my UI rules", or similar lifecycle requests.
---

# Personal Rules Management

Companion skill for `steering/personal-rules-protocol.md`. Use this when the user wants to inspect, edit, or remove their personal steering rules.

## Triggers

The user says any of:

- "What personal rules do I have?"
- "List my personal rules"
- "Show me my personal steering"
- "Forget about the X rule" / "Remove my X rule"
- "Update my X preference"
- "Merge / consolidate my personal rules"
- "Why isn't rule X being followed?"

## Listing

```bash
ls -la ~/.kiro/steering/personal-*.md 2>/dev/null
```

Then for each file, summarize:

- File name
- Inclusion filter (from frontmatter)
- One-sentence description
- When it was created (from `## Source` footer)

Format:

```
You have 3 personal rules:

1. personal-ui-style.md (fileMatch: **/*.{tsx,jsx,css,scss})
   "Pastel colors + light theme in React UIs"
   Created 2026-05-16 from explicit signal

2. personal-test-framework.md (auto)
   "Default to pytest for Python tests"
   Created 2026-05-17 from repetition

3. personal-deployment-prefs.md (always)
   "Always include --profile flag in deploy.sh examples"
   Created 2026-05-19 from explicit signal
```

## Updating in Place

When the user wants to extend a rule:

1. Read the existing file
2. Show the user the current content
3. Show the proposed diff
4. Wait for confirmation
5. Write changes (in place — never create `personal-X-v2.md`)
6. Update the `## Source` footer with the modification reason

## Removing

When the user says "forget about X" / "remove that rule":

1. Find the matching file via fuzzy match on topic or filename
2. If multiple match, list candidates and ask which one
3. Show the file content one last time before deletion
4. Confirm: "Delete `personal-X.md`? This is permanent — I cannot undo it from inside this session."
5. On `yes`, `rm ~/.kiro/steering/personal-X.md`
6. Confirm deletion

## Consolidating

When the user has 2+ related personal rules (or count exceeds 10), offer consolidation:

1. Identify related rules (e.g., `personal-ui-color.md` + `personal-ui-spacing.md` → `personal-ui-style.md`)
2. Propose the merged file:
   - New filename
   - New `inclusion` filter (broader if needed)
   - Combined body
   - Combined `## Source` (list all original triggers)
3. Show the proposed merge to the user
4. Wait for confirmation
5. Write the new merged file FIRST, then delete the originals (atomicity — never leave the system half-merged)

## Conflict Reporting

When the user asks "why isn't rule X being followed?":

1. Verify the file exists at `~/.kiro/steering/personal-X.md`
2. Check the `inclusion` field — is it scoped to the current task?
   - `always` → should always load
   - `fileMatch` → only loads when matching files are open/edited
   - `auto` → only loads when keywords match the current task
   - `manual` → only loads when explicitly invoked
3. Check for conflicts with `inclusion: always` base rules. Personal still wins, but verify the rule actually contradicts (it might just be additive)
4. Report findings and suggest a fix (broaden inclusion, or move keywords into description)

## Staleness Review

When personal rule count exceeds 10, OR every 30 days when the user starts a session:

1. Scan all `personal-*.md` files
2. For each, note creation date from `## Source`
3. Surface rules older than 60 days with: "Still want this rule? `personal-X.md` was created on YYYY-MM-DD — confirm it still applies, or I can remove it."
4. User can `keep`, `remove`, or `update` each one

## Boundaries

- NEVER auto-delete a personal rule without explicit confirmation
- NEVER modify a personal rule silently — always show diff first
- NEVER commit personal rules to git (they're gitignored, but never `git add steering/personal-*.md`)
- If the user asks why their rule is "missing from the GitHub repo" — explain it's by design (gitignored, local-only)

## Privacy

Personal rule files are readable on-disk. Before writing OR updating any rule, check the body for credential-like patterns:

- AWS access keys (`AKIA[A-Z0-9]{16}` or starting with `ASIA`)
- API tokens (`ghp_`, `sk-`, `pat_`, etc.)
- Email addresses, phone numbers, SSNs, addresses, full legal names tied to private accounts
- Database connection strings, JDBC URLs with credentials
- Private SSH or PGP keys

If detected, REFUSE to write the file and tell the user to rephrase the rule generically.

## See Also

- `steering/personal-rules-protocol.md` — the meta-rule that drives creation
- `steering/post-task-recommendations.md` — rules for ending responses
