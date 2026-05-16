---
inclusion: always
name: personal-rules-protocol
description: Self-evolving personal steering rules. Detects user preferences (explicit signals or repetition) and proposes saving them as gitignored personal-*.md steering docs that override base rules on the user's machine.
---

# Personal Rules Protocol (MANDATORY)

This config supports **self-evolving personal steering** — when the user expresses a preference that should apply to future work, you propose saving it as a local-only steering doc. Future sessions automatically inherit it via Kiro's steering loader.

These personal rules:

- Live at `~/.kiro/steering/personal-<topic>.md`
- Are gitignored (`.gitignore` excludes `steering/personal-*.md`)
- Are excluded from `./export-kiro.sh` (never shared)
- **ALWAYS WIN** over base rules in this repo when there's a conflict
- Are unique to the user's machine

## When to Suggest Creating a Personal Rule

Trigger on EITHER signal:

### A. Explicit signals

The user says any of these (case-insensitive):

- "always …"
- "never …"
- "from now on …"
- "going forward …"
- "I prefer …" / "I always prefer …"
- "make sure to …"
- "I want you to always …"

### B. Within-session repetition

The user has stated the same preference **2 or more times** in the current conversation, even without an explicit signal. Examples:

- Asks for pastel colors in two separate UI tasks → trigger
- Tells you to use Vitest twice → trigger
- Mentions they want passkey-first auth in three tasks → trigger

When either signal fires, follow the confirmation flow below.

## Confirmation Flow (MANDATORY)

You MUST always confirm before writing a personal rule. Never silently create one.

1. **Identify the rule** — distill the preference into one or two sentences
2. **Pick a filename** — `personal-<topic>.md` (kebab-case, descriptive). Examples:
   - `personal-ui-style.md`
   - `personal-test-framework.md`
   - `personal-deployment-prefs.md`
   - `personal-naming-conventions.md`
3. **Pick the right `inclusion` filter** based on rule scope:

   | Scope of rule                          | Inclusion                                                                              |
   | -------------------------------------- | -------------------------------------------------------------------------------------- |
   | Applies to every session, every task   | `always`                                                                               |
   | Applies when working on specific files | `fileMatch` with `fileMatchPattern` (e.g., `'**/*.{tsx,jsx,css,scss}'` for UI styling) |
   | Applies when the topic comes up        | `auto` (then write a rich `description` with keywords)                                 |
   | Applies only when explicitly invoked   | `manual`                                                                               |

4. **Check for conflicts** with existing base rules in `~/.kiro/steering/*.md` (excluding other `personal-*.md`). If a conflict exists, mention it and note that the personal rule will win.

5. **Show the user**:
   - Filename you'd create
   - Full proposed content (frontmatter + body)
   - Any conflicts you detected
   - A brief sentence explaining what changes for future sessions

6. **Wait for explicit confirmation**. Only proceed if the user replies with `yes`, `confirm`, `save it`, `do it`, or similar affirmative.

7. **Write the file** to `~/.kiro/steering/personal-<topic>.md` and confirm: "Saved. Future sessions will follow this rule automatically. Edit anytime at `~/.kiro/steering/personal-<topic>.md`."

8. **Never commit it** — these files are gitignored. If the user asks why their rule isn't in git, explain that personal rules are intentionally local-only.

## File Format

Every `personal-*.md` file MUST have YAML frontmatter:

```markdown
---
inclusion: <always|auto|fileMatch|manual>
name: personal-<topic>
description: <one-sentence summary, used by the auto-loader to match keywords>
fileMatchPattern: <optional, only when inclusion is fileMatch>
---

# <Topic title>

<Body — the rule itself, explained clearly. Use bullet points or short prose.>

## Source

Created automatically by personal-rules-protocol on <date>.
Trigger: <explicit signal | repetition>.
Original user request: "<short quote of what the user said>"
```

The "Source" section is mandatory — it documents WHY the rule exists, which makes it easy for the user to review and prune later.

## Conflict Policy: Personal Always Wins

If a personal rule contradicts a base rule (e.g., `personal-test-framework.md` says "always Jest" but `tech.md` says "Vitest"), the personal rule wins. You don't need to ask which takes precedence — personal-always-wins is the policy.

When you detect a conflict during confirmation, simply note it: "This will override the rule in `tech.md` that says X. Personal rules always win on your machine."

## Existing Personal Rule Management

When the user wants to:

| Request                                                   | Action                                                                          |
| --------------------------------------------------------- | ------------------------------------------------------------------------------- |
| "What personal rules do I have?"                          | `ls ~/.kiro/steering/personal-*.md` and summarize each                          |
| "Forget about the pastel UI rule" / "remove that rule"    | Find the matching `personal-*.md` and offer to delete it. Confirm before `rm`   |
| "Update my UI preference to also include rounded corners" | Edit the existing `personal-ui-style.md` in place; show the diff before writing |
| "Why isn't my rule in the GitHub repo?"                   | Explain it's gitignored on purpose — personal rules are local-only              |

## Bloat Prevention

If `~/.kiro/steering/personal-*.md` count exceeds 10:

- Suggest reviewing them in your next response
- Offer to consolidate related rules (e.g., merge `personal-ui-color.md` + `personal-ui-spacing.md` into `personal-ui-style.md`)
- Prefer `inclusion: auto` or `fileMatch` over `always` to keep base context lean

## Examples

### Example 1: Explicit signal

User: "From now on, always use pastel colors and a light theme when building React UIs."

Agent: "Got it. I'd propose saving this as a personal steering rule:

**Filename**: `personal-ui-style.md`
**Inclusion**: `fileMatch` on `**/*.{tsx,jsx,css,scss}`
**Content**:
\`\`\`markdown

---

inclusion: fileMatch
name: personal-ui-style
description: User prefers pastel colors and light themes in React UIs. Apply when generating or modifying UI components and styles.
fileMatchPattern: '\*_/_.{tsx,jsx,css,scss}'

---

# Personal UI Style Preferences

- Always use a **pastel color palette** (soft pinks, mint greens, lavenders, sky blues, butter yellows)
- Always design for **light theme** (not dark mode) unless explicitly asked otherwise
- Avoid harsh primary colors (pure red, pure blue, pure black backgrounds)

## Source

Created automatically by personal-rules-protocol on 2026-05-16.
Trigger: explicit signal ("from now on, always …").
Original user request: "From now on, always use pastel colors and a light theme when building React UIs."
\`\`\`

This will live at `~/.kiro/steering/personal-ui-style.md`, gitignored, and apply to all future UI work. Save it?"

User: "yes"

Agent writes the file and confirms.

### Example 2: Repetition signal

After the user has asked for "tests with pytest, please" three times across the same conversation, the agent surfaces:

> "I noticed you've asked for pytest specifically a few times. Want me to save 'always use pytest for Python tests' as a personal rule so I default to it without you asking each time? It would go in `~/.kiro/steering/personal-test-framework.md`."

User confirms or declines.

## Don't Do

- Don't trigger on a single mention without an explicit signal — wait for repetition or "always"
- Don't save personal rules silently — always confirm
- Don't put project-specific rules in personal — those belong in `.kiro/steering/` inside the project repo
- Don't include credentials, secrets, or PII in personal rules — they're local but still readable
- Don't propose a personal rule that contradicts a steering doc the user just edited (they probably did it on purpose)
