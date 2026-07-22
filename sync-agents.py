#!/usr/bin/env python3
"""sync-agents.py — keep V2 agent JSON in sync with the canonical V3 Markdown agents.

The V3 files (~/.kiro/agents/*.md) are the SINGLE SOURCE OF TRUTH.
This script propagates the shared fields into the V2 files so both engines
describe the same agents:

  agents/<name>.md  --->  prompts/<name>.md      (body -> V2 system prompt)
                    --->  agents/<name>.json     (description, welcomeMessage,
                                                  keyboardShortcut, mcpServers,
                                                  prompt file://, resources)

V2-specific fields in the JSON are preserved as-is: tools, allowedTools,
toolsSettings, hooks, model. (V2 has no tag-based tools; ["*"] + toolsSettings
remains the V2 access model.)

MCP conversion notes:
  - V3-only per-server fields (timeout, requestTimeout) are stripped for V2.
  - "disabled": false is added per repo convention.

Usage:
  ./sync-agents.py           # write mode: sync .json + prompts/ from .md
  ./sync-agents.py --check   # parity mode: exit 1 if anything is out of sync
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import yaml

KIRO = Path(os.environ.get("KIRO_DIR", Path(__file__).resolve().parent))
AGENTS = KIRO / "agents"
PROMPTS = KIRO / "prompts"

SYNCED_KEYS = ("description", "welcomeMessage", "keyboardShortcut")


def load_md(path: Path) -> tuple[dict, str]:
    txt = path.read_text()
    if not txt.startswith("---"):
        raise ValueError(f"{path.name}: missing frontmatter")
    _, fm_raw, body = txt.split("---", 2)
    return yaml.safe_load(fm_raw), body.strip() + "\n"


def convert_mcp(md_servers: dict) -> dict:
    out: dict = {}
    for name, cfg in (md_servers or {}).items():
        c = dict(cfg)
        c.pop("timeout", None)         # V3-only
        c.pop("requestTimeout", None)  # V3-only
        c.setdefault("disabled", False)
        out[name] = c
    return out


def main() -> int:
    check = "--check" in sys.argv
    drift: list[str] = []

    for md_path in sorted(AGENTS.glob("*.md")):
        name = md_path.stem
        fm, body = load_md(md_path)

        json_path = AGENTS / f"{name}.json"
        prompt_path = PROMPTS / f"{name}.md"

        expected_prompt_ref = f"file://~/.kiro/prompts/{name}.md"
        expected_mcp = convert_mcp(fm.get("mcpServers", {}))
        expected_resources = list(fm.get("resources", []))

        cur = json.loads(json_path.read_text()) if json_path.exists() else {"name": name, "tools": ["*"]}

        desired = dict(cur)
        desired["name"] = name
        for k in SYNCED_KEYS:
            if k in fm:
                desired[k] = fm[k]
        desired["prompt"] = expected_prompt_ref
        desired["mcpServers"] = expected_mcp
        desired["resources"] = expected_resources

        json_in_sync = json_path.exists() and cur == desired
        prompt_in_sync = prompt_path.exists() and prompt_path.read_text() == body

        if check:
            if not json_in_sync:
                drift.append(f"{name}.json out of sync with {name}.md")
            if not prompt_in_sync:
                drift.append(f"prompts/{name}.md out of sync with agents/{name}.md body")
            continue

        if not prompt_in_sync:
            prompt_path.write_text(body)
            print(f"  wrote prompts/{name}.md")
        if not json_in_sync:
            json_path.write_text(json.dumps(desired, indent=2, ensure_ascii=False) + "\n")
            print(f"  wrote agents/{name}.json")

    if check:
        if drift:
            for d in drift:
                print(f"  x {d}")
            return 1
        print("  V2/V3 agent parity OK")
        return 0

    print("sync complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
