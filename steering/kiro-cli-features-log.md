---
inclusion: manual
name: kiro-cli-features-log
description: 'Running log of Kiro CLI feature releases through 2.20.1 (side channels, OAuth, /rewind, model effort, subagent review loops, cloud sessions, /voice, global hooks, etc). Load manually when checking what shipped in a specific version — not needed for day-to-day agent work.'
---

# Kiro CLI Features Worth Knowing (through 2.20.1)

- **Agent output side channels** (2.3.0) — `$AGENT_DISPLAY_OUT` and `$AGENT_CONTEXT_OUT` env vars in shell commands route verbose output to the user TUI without polluting agent context (used by `deploy.sh`)
- **OAuth Client ID for HTTP MCP servers** (2.3.0) — set `oauth.clientId` in MCP config to use Slack/GitHub/Figma HTTP MCP servers without DCR (we don't need this — our MCPs are stdio)
- **`KIRO_HOME` env var** (2.3.0) — relocate the global config directory if needed
- **Configurable V2 TUI keybindings** (2.3.0) — remap Ctrl+C / Esc / quit if they conflict with tmux
- **`/rewind`** (2.4.0, enriched in 2.7.0) — jump back to an earlier prompt and branch into a new session; the turn picker now previews tool calls, files touched, and commands run per turn
- **Model reasoning effort** (2.4.0) — `/effort` (low / medium / high / xhigh / max) tunes how hard the model thinks; `--effort` sets it at launch (2.6.0)
- **Subagent review loops** (2.5.0) — reviewer→implementer loops for self-correcting pipelines (see `steering/AGENTS.md` → "Subagent Review Loops")
- **Thinking display** (2.5.0) — streams the model's reasoning live; on by default, toggle via `/settings display`
- **Transcript export** (2.6.0) — `/transcript save` exports a conversation as markdown/plaintext/JSON
- **Persistent model + effort prefs** (2.6.0) — `/model` and `/effort` choices stick across sessions automatically (no more `set-current-as-default`)
- **`/goal`** (2.7.0) — start an iterative loop where the agent works toward an objective and must verify completion before stopping (default 5 iterations, `--max` configurable). Aligns with this config's quality-gate philosophy.
- **Queue steering** (2.7.0) — send a correction while the agent is working; it picks it up at the next tool boundary. `Ctrl+S` toggles steer mode (inject mid-turn) vs queue mode (buffer until turn ends).
- **MCP auth management** (2.11.0) — `/mcp auth`, `/mcp cancel-auth`, `/mcp logout` for remote MCP OAuth; MCP-panel shortcuts `^A`/`^X`/`^R`.
- **Expanded MCP OAuth** (2.12.0) — `clientSecret` + custom `redirectUri` callback paths + skip Dynamic Client Registration with your own `clientId` (e.g., Figma); more accurate approval prompts for combined-flag commands; full ASCII mode.
- **Config Hot-Reload** (2.10.0) — agent and MCP config changes reconcile **live on save**: no session restart, only affected MCP servers restart, conversation context preserved, order-independent diff (reordering env vars won't trigger a restart). Editing an agent JSON or `mcp.json` now takes effect immediately. Also adds `chat.disableInheritingDefaultResources` to stop custom agents from inheriting default steering/skills/AGENTS.md (they inherit by default since 2.7.0).
- **`/upgrade-agent`** (2.14.0) — migrates a V2 agent config in place to the universal format that works with both V2 and V3, without a full V3 rewrite.
- **Guided spec creation + Plan auto-execution** (2.15.0) — `/spec new` asks for a description before drafting requirements instead of guessing from the name alone; in Plan mode, approving a plan now starts execution immediately (no manual mode switch).
- **Tangent side-conversations** (2.16.0) — `/tangent` branches into a side-conversation that inherits full history, explores freely, then returns to the main thread; `/tangent ls` shows a visual picker; `/context` gains a per-tool token breakdown.
- **Cloud sessions (preview)** (2.17.0) — `kiro-cli --cloud` runs a session in a managed cloud sandbox; disconnect and resume from any machine with `--resume-id`. Slash-command menu gained substring matching.
- **`/voice`** (2.18.0) — dictate prompts via on-device Whisper transcription (no audio leaves the machine, no cloud API key). Spec review screen gained a checkpoint comment-and-revise flow (`Ctrl+X`). **`AGENTS.md` files now load as steering context from anywhere in the workspace tree**, not just the root and `~/.kiro/steering/` — an `AGENTS.md` next to the code it describes gets picked up automatically.
- **Mouse support + stream resilience** (2.19.0) — mouse support in the spec review screen (scroll/click, toggle with `m`); an idle-stream watchdog + automatic retry-with-backoff + 60-minute streaming timeout mean a dropped/throttled connection no longer hangs or ends a turn (tunable via `api.streamIdleSoftTimeout` / `api.streamIdleHardTimeout` / `api.timeout`).
- **Global hooks** (2.13.0, V3-only) — hooks placed in `~/.kiro/hooks/` now fire in every workspace automatically, not just the one they're defined in, so cross-cutting behaviors (lint-on-save, pre-commit security checks, custom approval gates) don't need per-project duplication. Workspace-level hooks still work alongside global ones. **Not yet usable in this repo as-is** — this repo's hooks are all inline `hooks` blocks inside each agent's JSON, not standalone files in a `hooks/` directory, so there's nothing to promote to global scope without a structural change.
- **`/spec run` full-screen task view + scrollback** (2.20.0) — `/spec run` now opens a full-screen task execution view with real-time progress and a task-scope selection step before execution starts; a new "Preserve scrollback" toggle keeps terminal history available through output overflow and window-resize redraws.
