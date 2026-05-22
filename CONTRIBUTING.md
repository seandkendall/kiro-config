# Contributing

Thanks for considering a contribution. This is a personal multi-agent Kiro CLI configuration shared publicly for reference and reuse — drive-by improvements, bug reports, and pattern suggestions are welcome.

## Before You Push

Always run the local pre-push validator:

```bash
./validate.sh
```

It checks:

1. Every agent JSON validates against Kiro CLI's schema (`kiro-cli agent validate`)
2. All JSON files parse cleanly
3. Bash scripts have no syntax errors
4. The privacy guard — no `personal-*.{json,md}` files have leaked into git

The script prints `✓ All checks passed. Safe to push.` when green.

## Documentation Sync Rule

When you modify anything in this repo, **update `CHANGELOG.md` AND `README.md` in the same commit** if your change affects:

- The agent table (additions, removals, renames)
- The skills count or table
- The MCP server table
- Required environment variables
- Prerequisites or installation steps
- Configuration defaults (model, settings)

Don't defer doc updates to a separate commit. The pre-push validator doesn't enforce this — it's an honor-system rule.

## Hard Rules

- **CDK in Python only** — never TypeScript for infrastructure
- **TypeScript only for React frontends**
- **No CI/CD pipelines, no git hooks** — both are explicitly banned in `steering/post-task-recommendations.md`. Validation belongs in `./validate.sh`.
- **MCP-over-CLI** — github MCP for github.com operations (not `gh`), `aws-mcp-server` for AWS (not bare `aws`). Local git operations (`status`, `diff`, `log`, `add`, `commit`, `push`) are still fine via shell.

## File Modification

Always edit files in place. Never create `file_v2.py`, `file_new.py`, `file_backup.md` alongside the original. If the file exists, modify it.

## Personal Rules Stay Local

The `personal-*.md`, `agents/personal-*.json`, and `prompts/personal-*.md` patterns are gitignored. If you have personal preferences (e.g., UI style, test framework, deployment quirks), let the agent suggest them as personal rules per `steering/personal-rules-protocol.md` — they live on your machine and never get committed.

## License

By contributing, you agree your contributions will be licensed under the [Apache License 2.0](LICENSE).
