# Changes

A chronological log of change-sets made to this project. Each round is one set of
changes recorded before handing back to the user. Newest rounds are appended to the bottom.

## Round 1 — 2026-06-16 18:25:28 -04:00

- Added `steering/change-logging.md` — new `inclusion: always` steering doc mandating a per-project `CHANGES.md` with round-numbered, timestamped, GitHub-friendly entries
- Updated `README.md` — bumped always-loaded steering doc count 16 → 17 (intro + "Steering Docs" header) and added "change logging" to the topics list
- Updated `CHANGELOG.md` — added `[0.15.0]` entry documenting the new steering rule
- Added this `CHANGES.md` file at the repo root and recorded `Round 1`

## Round 2 — 2026-06-23 11:00:08 -06:00

- Fixed image generation being unreachable from `master`: added `bedrock-image-mcp-server` to `agents/master.json` `mcpServers` (on-demand via Tool Search)
- Added `"AWS_REGION": "us-east-1"` to the `bedrock-image-mcp-server` env in `agents/image-gen.json`, `frontend.json`, `web-builder.json`, and `ai-builder.json`
- Updated `prompts/master.md` — image-generation workflow now covers direct tool use plus `image-gen` delegation
- Updated `agents/master.json` welcome message to mention image generation
- Updated `README.md` — corrected the Bedrock Image MCP server agent list
- Added `[0.16.0]` entry to `CHANGELOG.md`; verified the MCP server exposes 20 tools via a live stdio handshake and `./validate.sh` passed
