#!/usr/bin/env python3
"""Self-test for sync-agents.py (stdlib only — run: python3 tests/test_sync_agents.py).

Covers:
  1. Generation: .md frontmatter + body -> .json + prompts/<name>.md
  2. V2-only fields (tools/toolsSettings/hooks) preserved on re-sync
  3. V3-only MCP fields (timeout) stripped; disabled:false added
  4. --check passes when in sync, fails (exit 1) on injected drift
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SYNC = REPO / "sync-agents.py"

MD = """---
description: "Test agent"
keyboardShortcut: ctrl+5
welcomeMessage: "hi"
tools: [read, write]
mcpServers:
  demo:
    command: uvx
    args: [demo-mcp]
    timeout: 180000
resources:
  - file://README.md
permissions:
  rules:
    - capability: shell
      effect: deny
      match: ["git-defender*"]
---

You are a test agent body.
"""


def run_sync(kiro_dir, *args):
    return subprocess.run(
        [sys.executable, str(SYNC), *args],
        env={**os.environ, "KIRO_DIR": str(kiro_dir)},
        capture_output=True, text=True,
    )


class TestSyncAgents(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.kiro = Path(self.tmp.name)
        (self.kiro / "agents").mkdir()
        (self.kiro / "prompts").mkdir()
        (self.kiro / "agents" / "testagent.md").write_text(MD)

    def tearDown(self):
        self.tmp.cleanup()

    def test_generation_and_conversion(self):
        r = run_sync(self.kiro)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        j = json.loads((self.kiro / "agents" / "testagent.json").read_text())
        self.assertEqual(j["name"], "testagent")
        self.assertEqual(j["description"], "Test agent")
        self.assertEqual(j["keyboardShortcut"], "ctrl+5")
        self.assertEqual(j["prompt"], "file://~/.kiro/prompts/testagent.md")
        self.assertNotIn("timeout", j["mcpServers"]["demo"])          # V3-only stripped
        self.assertIs(j["mcpServers"]["demo"]["disabled"], False)      # convention added
        body = (self.kiro / "prompts" / "testagent.md").read_text()
        self.assertIn("You are a test agent body.", body)

    def test_v2_only_fields_preserved(self):
        run_sync(self.kiro)
        jp = self.kiro / "agents" / "testagent.json"
        j = json.loads(jp.read_text())
        j["tools"] = ["*"]
        j["toolsSettings"] = {"shell": {"deniedCommands": ["git-defender.*"]}}
        jp.write_text(json.dumps(j, indent=2) + "\n")
        run_sync(self.kiro)  # re-sync must not clobber V2-only fields
        j2 = json.loads(jp.read_text())
        self.assertEqual(j2["tools"], ["*"])
        self.assertIn("toolsSettings", j2)

    def test_check_detects_drift(self):
        run_sync(self.kiro)
        self.assertEqual(run_sync(self.kiro, "--check").returncode, 0)
        # inject drift into the json
        jp = self.kiro / "agents" / "testagent.json"
        j = json.loads(jp.read_text()); j["description"] = "DRIFTED"
        jp.write_text(json.dumps(j, indent=2) + "\n")
        self.assertEqual(run_sync(self.kiro, "--check").returncode, 1)
        # sync repairs it
        run_sync(self.kiro)
        self.assertEqual(run_sync(self.kiro, "--check").returncode, 0)

    def test_check_detects_prompt_drift(self):
        run_sync(self.kiro)
        (self.kiro / "prompts" / "testagent.md").write_text("stale body\n")
        self.assertEqual(run_sync(self.kiro, "--check").returncode, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
