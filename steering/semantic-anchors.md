---
inclusion: manual
name: semantic-anchors
description: 'Write steering docs by naming established methods/specs instead of re-describing them, spelling out only the project-specific delta. Load manually when authoring or editing a steering doc, skill, or agent prompt — not needed for day-to-day coding tasks.'
---

# Semantic Anchors

## Core Principle

**Name an established concept instead of re-describing it, and spell out only the delta where this repo diverges from the canonical definition.** A model already carries a rich, shared understanding of well-known specs and conventions. Saying "WCAG 2.2 AA" or "Conventional Commits" loads that whole specification in a couple of words. Re-explaining it in a paragraph wastes tokens, invites drift from the real spec, and risks contradicting what the model already knows more precisely than a paraphrase can.

This repo's steering docs get shorter, sharper, and easier to maintain when they lean on anchors and reserve prose for the parts a model cannot guess — the project-specific delta.

## Rules

1. Name an established method by its canonical term instead of describing its rules from scratch.
2. Spell out only the delta — the specific ways this repo diverges from the anchor's canonical definition.
3. Run the Anchor Validity Test (Precise, Rich, Consistent, Attributable — see below) before treating a term as an anchor.
4. Verify recognition before relying on an anchor for something load-bearing: ask the model what it associates with the term. If the answer is vague or wrong, don't anchor on it — write the behavior out instead.
5. Never reduce content that requires deterministic, tool-checked validation (specific markdownlint rule IDs, an exact JSON/CFN shape, a specific IAM policy structure) to a bare anchor name — a linter or `cdk synth` can't verify a label.

## The Anchor Validity Test

A term is a usable anchor only if it passes all four:

1. **Precise** — points to one specific, well-bounded concept, not a vague aspiration.
2. **Rich** — unpacks into substantial detail the model can actually apply, not just a label.
3. **Consistent** — independent sources agree on what it means; the definition is stable.
4. **Attributable** — traces to a nameable spec, standard, or well-known convention.

Terms that fail this test only _look_ like instructions:

- **"best practices"** — fails Precise and Consistent. Sounds good; no two readers expand it into the same rules.
- **"make it secure"** — fails Rich and Attributable. Carries a mood, not a method.
- **"clean code"** — fails Precise. Points at a vague aspiration, not a specific rule set.

When a term fails the test, write the behavior out instead of pretending the name carries it — this is exactly what most of this repo's existing MANDATORY rules already do correctly (e.g., the exact deploy.sh flag contract in `aws-standards.md` is Tier 3 by nature — there's no canonical spec for it, so it's fully spelled out, which is correct).

## Three-Tier Classification

Classify a rule before deciding how to write it. Examples below are drawn from this repo's own steering docs — not hypotheticals.

- **Tier 1 — an established anchor exists and prose is redundant.** Name the anchor and stop.
  - `accessibility-standards.md` already does this correctly: naming "WCAG 2.2 AA," "Focus Not Obscured," "Target Size (Minimum)," "Accessible Authentication (Minimum)" activates the full W3C specification rather than re-describing each criterion.
  - `security-policies.md`'s OWASP section (XSS, CSRF, injection, broken auth) already names the anchor (OWASP) rather than re-deriving each vulnerability class from scratch.

- **Tier 2 — an anchor exists but this repo adds a delta.** Name the anchor, then state only the divergence.
  - `python-standards.md` is implicitly PEP 8 + house deltas (f-strings over `.format()`, `pathlib` over `os.path`, dataclasses/pydantic over plain dicts) — it could be tightened to explicitly anchor on PEP 8 first, then list only the deltas, rather than restating general Python style from scratch.
  - `aws-standards.md`'s Cognito password-policy rule is a good existing Tier 2 example: "Use Cognito's **default** password policy... unless a developer explicitly requests different rules" — it doesn't re-derive what a good password policy is, it anchors on the service default and states the override condition as the only delta.

- **Tier 3 — no anchor exists, so the content itself is the signal.** Write it out in full; there's nothing for the model to recall.
  - `aws-standards.md`'s exact `deploy.sh` flag contract (`--profile`, `--domain`, `--delete`, `-y`, `-h`) and its deep-cleanup-on-delete behavior are pure house convention — no upstream spec defines them, so every detail must stay written out.
  - `change-logging.md`'s `CHANGES.md` round-numbering format is a coined, repo-specific convention — write it out in full (this doc already does).

## A concrete fix this repo can apply

`ios-standards.md` → "Git & Source Control" currently states:

```text
Commit message format: `feat(tripPlanning): add waypoint reordering`
```

This is Conventional Commits, stated as a bare example instead of named. The anchor version:

```text
Follow Conventional Commits (type(scope): summary — e.g. feat(tripPlanning): add waypoint reordering).
```

Same behavior, and now explicit that the model should apply the full Conventional Commits spec (types like `fix`, `docs`, `refactor`, breaking-change footers, etc.), not just pattern-match the one example shown. Not yet applied to `ios-standards.md` — this doc only defines the technique; apply it opportunistically the next time that file (or any other) is touched, rather than as a standalone editing pass.

## What This Prevents

- **Token waste** from re-describing methods the model already knows in full.
- **Definition drift** where a hand-written paraphrase slowly diverges from the upstream spec (e.g., a hand-rolled WCAG summary that misses a new 2.2 criterion — the exact gap found and fixed in `accessibility-standards.md` this session).
- **False anchors** from vague terms like "best practices" that read like instructions but carry no shared meaning.
- **Silent rule loss** from collapsing deterministic, tool-checked content (deploy.sh's flag contract, IAM policy shapes, CFN resource names) into a name a linter or `cdk synth` can't verify.

## When To Apply This

This doc is `inclusion: manual` — it's a meta-rule about _how to write other steering docs_, not a rule for everyday coding tasks, so it shouldn't load into every session's context. Load it explicitly (`skill://` reference or manual read) when:

- Authoring a new steering doc, skill, or agent prompt.
- Reviewing an existing doc for bloat or drift (e.g., during the periodic steering-review passes this repo already does).
- Deciding whether a new rule needs full prose or can just name a spec.

Don't apply it to Tier 3 content that's already correctly spelled out — the goal is trimming redundant re-explanation of things the model already knows, not compressing everything into terse labels.

## Attribution

Adapted from the [Semantic Anchors catalog](https://llm-coding.github.io/Semantic-Anchors/) by Ralf D. Müller and the LLM Coding community, via the community `kiro-steering-docs` collection (`mikeartee/kiro-steering-docs`), and the AWS Builder Center article "Semantic Anchors + Kiro Steering: Name It, Don't Describe It" by Jörn Krüger. Rewritten for this repo's own conventions and examples rather than copied verbatim.
