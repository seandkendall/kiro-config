---
inclusion: manual
name: capability-placement
description: 'Decision framework for where a capability belongs: always-on steering doc, on-demand skill, deterministic script/MCP tool, or a delegated sub-agent. Load manually when adding a new rule, skill, or MCP integration, or when deciding whether something should be a markdown instruction vs. executable code.'
---

# Capability Placement

Four places a capability can live in this config, and how to pick one. Based on AWS's own
guidance for agent skills and the Well-Architected Agentic AI Lens — see Attribution.

## The Four Levers

| Lever | Loads | Best for | Token cost |
| --- | --- | --- | --- |
| **Steering doc** (`steering/*.md`) | Unconditionally, every session (`inclusion: always`) or on trigger (`auto`/`fileMatch`) | Standing policy that must never be skipped — security rules, tech stack, no-CI/CD | Pays every session; keep each doc small (cap ~25KB/~120 lines per the AWS DevOps Agent Skills post) |
| **Skill** (`skills/<name>/SKILL.md`) | On demand, when description keywords match the task | Scenario-specific playbooks — "how to do X when X comes up," not "always remember X" | Pays only when triggered; target under ~5,000 tokens for the initial load (reference files load lazily) |
| **Script or MCP tool** | On demand, executed not read | Deterministic operations: fixed sequences, external data fetches, real-time info, complex computation, service integrations | Near-zero — the model calls it, doesn't re-derive the steps each time |
| **Sub-agent** (`agents/*.json`) | Delegated, runs in an isolated context | A capability that needs its own tool set, its own focused prompt, or genuinely independent work (atomic task, per AGENTREL02-BP01) | A full context window per invocation — most expensive lever, use when the other three don't fit |

These are not substitutes for each other — picking the wrong one for a given capability either
wastes tokens (steering-izing something that's only occasionally needed) or loses reliability
(skill-izing something that must never be skipped).

## Decision Tree

```
Does this capability need to apply on EVERY session, unconditionally?
│
├─ YES → steering doc, inclusion: always
│         (security policy, tech stack, no-CI/CD — never optional)
│
└─ NO → Is it triggered by a specific task/topic, and is it markdown instructions
         (not a fixed script)?
         │
         ├─ YES → skill (steering doc with inclusion: auto/fileMatch/manual also
         │         works for narrower, still-markdown triggers — see
         │         `steering/AGENTS.md` for the inclusion filter table)
         │
         └─ NO → Is the sequence of steps FIXED and deterministic (same steps,
                  same order, every time) or does it need external/real-time data,
                  a complex computation, or a live service call?
                  │
                  ├─ YES → script (deterministic skill, code does the work,
                  │         markdown shrinks to "run this, use the result") or
                  │         an MCP tool if the capability already exists as one
                  │
                  └─ NO → Does it need an isolated context, its own tool set, or
                           genuinely independent focused work?
                           │
                           ├─ YES → sub-agent
                           └─ NO  → reconsider; it's probably steering or skill content
```

## Normal Skill vs. Deterministic Skill

A **normal skill** is markdown instructions the model re-interprets every time it's loaded —
flexible, but inconsistent under repetition or load (the model can paraphrase a step
differently each run). A **deterministic skill** moves the fixed steps into an actual script or
tool call; the markdown shrinks to "run this script, use its output" instead of describing the
procedure in prose. The Agent Toolkit's own skill model confirms this: a skill's reference files
can include "code scripts for deterministic operations," not just reference docs.

**Rule of thumb:** if a skill's instructions read like a numbered list of exact commands with no
judgment calls, that's a sign that sequence belongs in a script the skill invokes, not prose the
model re-derives each time.

## MCP Tool vs. Inline Instructions

From the AWS Labs agent-plugins design guidelines:

- **Use an MCP tool** for external data, real-time information, complex computation, or service
  integrations — anything where the agent needs to reach outside its own reasoning.
- **Use inline instructions** (steering or skill prose) for logic and decision-making, workflow
  orchestration, output formatting, and user-interaction patterns — anything that's really about
  how the agent should think or communicate, not what external system it should call.

This repo already applies this split via `mcp-server-preference.md` (MCP over CLI for every
configured server) and `aws-agent-toolkit.md` (AWS MCP Server over hand-rolled `boto3`/CLI).

## Sub-Agent Delegation Signal

Per the Well-Architected Agentic AI Lens (AGENTREL02-BP01, "design agents around atomic tasks"):
delegate to a sub-agent when a capability is an atomic, independently completable unit of work
with its own clear tool/capability taxonomy (AGENTREL04-BP02) — not just because a task is
long. A long task that still needs the parent's full context and decision state should stay
in-line; a task that can run with a narrower tool set and report back a self-contained result is
a delegation candidate. See `steering/AGENTS.md` → "Delegation Rules" for this repo's concrete
subagent roster and the `subagent` vs `delegate` tool choice.

## Failure Modes to Watch For

- **Conflicting skills** — two skills giving different guidance for the same trigger. Keep a
  skill inventory (this repo's skill table in `README.md`) and check for overlap before adding a
  new one.
- **Skill rot** — a skill's guidance goes stale as the underlying service/library changes. Add a
  `last_verified` note (informally, in the skill body) for anything that cites specific API
  behavior, version numbers, or pricing.
- **Overly rigid sequences** — a skill written as a strict numbered procedure with no escape
  branch fails badly on the first edge case. Add explicit "if X doesn't apply, do Y instead"
  branches rather than assuming the happy path always holds.
- **Duplicate scope** — a new skill partially overlaps an existing steering doc or skill. Check
  `README.md`'s skill table and run `search_symbols`/`grep_search` across `steering/` and
  `skills/` for the topic before writing a new file.

## Attribution

Synthesized from: the AWS DevOps Agent Skills best-practices post
(`aws.amazon.com/blogs/mt/best-practices-for-writing-aws-devops-agent-skills/`); the
`awslabs/agent-plugins` design guidelines
(`github.com/awslabs/agent-plugins/blob/main/docs/DESIGN_GUIDELINES.md`); the AWS Well-Architected
Agentic AI Lens (AGENTREL02-BP01, AGENTREL04-BP02); the Agent Toolkit for AWS skills documentation
(`docs.aws.amazon.com/agent-toolkit/latest/userguide/skills.html`); and the "normal skill vs.
deterministic skill" framing from a LinkedIn post by Balram R. — author's AWS/Amazon affiliation
could not be independently confirmed, so that specific framing is treated as a useful restatement
of the Agent Toolkit's own documented skill model, not as an authoritative AWS source on its own.
