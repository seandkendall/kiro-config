---
# ⚠️ DRAFT / PREVIEW — Kiro CLI V3 only. NOT loaded by the 2.x engine (which loads agents/*.json).
# This is a translation prototype for the eventual v2→v3 migration. Do not promote to
# agents/master.md until the official AWS migration guide lands and we validate on --v3.
# See steering/kiro-cli-v3-migration.md.
description: Master orchestrator agent — routes any task to the right specialist subagent
model: claude-opus-4.8
keyboardShortcut: ctrl+1
welcomeMessage: 'Master orchestrator ready. I route any task to the right specialist subagent (13 available), generate images and diagrams, and write deploy.sh scripts. What are we building?'

# v2 `"tools": ["*"]`  ->  v3 tag list. `*` already includes everything (incl. subagent);
# listed explicitly here to document intent for the migration.
tools: [read, write, shell, web, subagent, knowledge, todo_list, '@mcp', '@builtin']

# v2 `mcpServers` block — same shape, now inline in the agent profile.
mcpServers:
  web-search:
    command: uvx
    args: ['duckduckgo-mcp-server']
  context7:
    command: npx
    args: ['-y', '@upstash/context7-mcp']
  github:
    command: npx
    args: ['-y', '@modelcontextprotocol/server-github']
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
  sequentialthinking:
    command: npx
    args: ['-y', '@modelcontextprotocol/server-sequential-thinking']
  aws-mcp-server:
    command: uvx
    args:
      [
        'mcp-proxy-for-aws@latest',
        'https://aws-mcp.us-east-1.api.aws/mcp',
        '--metadata',
        'AWS_REGION=us-east-1',
      ]
  bedrock-image-mcp-server:
    command: uvx
    args: ['bedrock-image-mcp-server@latest']
    env:
      AWS_REGION: 'us-east-1'
      FASTMCP_LOG_LEVEL: 'ERROR'

resources:
  - file://AGENTS.md
  - file://README.md
  - file://~/.kiro/steering/*.md
  - skill://~/.kiro/skills/cdk-infrastructure-patterns.md
  - skill://~/.kiro/skills/react-frontend-patterns.md
  - skill://~/.kiro/skills/aws-serverless-patterns.md
  - skill://~/.kiro/skills/testing-patterns.md
  - skill://~/.kiro/skills/mcp-tool-discovery.md

# v2 toolsSettings.shell.deniedCommands + web_fetch.trusted  ->  capability rules.
# (deny > ask > allow; unmatched = ask.) Repo-shareable intent lives here; machine-local
# trust stays in the gitignored permissions.yaml.
permissions:
  - capability: shell
    effect: deny
    match: ['git-defender*']
  - capability: web_fetch
    effect: allow
    match: ['*docs.aws.amazon.com*', '*github.com*']
---

> **DRAFT V3 PROTOTYPE.** On real migration, the **body below becomes the system prompt** —
> replace this scaffold with the contents of `prompts/master.md` (the v2 `prompt: file://...`
> reference is gone in v3; the document body IS the prompt). Embedded `hooks` from
> `agents/master.json` (prettier/shfmt `postToolUse`) do NOT live here in v3 — they move to a
> standalone `.kiro/hooks/*.json` file (see `steering/kiro-cli-v3-migration.md` §2). Subagent
> access (v2 `availableAgents`/`trustedAgents`) is granted via the `subagent` tag above plus the
> `permissions` model — re-confirm trusted-agent scoping during migration.

You are a master orchestrator agent. Your job is to understand what the user needs and delegate
to the right specialist subagent(s). You can also handle simple tasks directly.

(Full system prompt to be inlined from `prompts/master.md` on migration. Kept as a pointer here
so this draft does not drift from the canonical v2 prompt while we remain on 2.x.)
