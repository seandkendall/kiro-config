---
inclusion: auto
name: troubleshooting
description: CDK deployment errors, Lambda cold starts, API Gateway CORS, Cognito auth failures, React build issues. Use when debugging errors, failures, or unexpected behavior.
---

# Troubleshooting Guide

## CDK Deployment Issues

**GSI Creation Errors**:

- Error: "Cannot perform more than one GSI creation or deletion"
- Solution: Deploy GSI changes one at a time, wait for completion

**Stack Name Conflicts**:

- Error: "Stack already exists"
- Solution: Use unique, project-specific stack names

**cdk-nag Failures**:

- Check security validation rules
- Add suppressions only with proper justification

## Lambda Function Issues

**Cold Start Performance**:

- Check memory allocation (512MB minimum recommended)
- Verify dependencies are optimized
- Review initialization code outside handler

**Permission Errors**:

- Verify IAM roles have required permissions
- Check resource-based policies
- Confirm execution role is attached

## API Gateway Issues

**CORS Errors**:

- Verify CORS configuration in CDK
- Check preflight OPTIONS requests
- Confirm allowed origins and headers

**Authentication Failures**:

- Verify Cognito JWT token format
- Check token expiration
- Confirm authorizer configuration

## React/Frontend Issues

**Build Failures**:

- Run `npm run lint` to check for errors
- Verify all imports are resolved
- Check TypeScript compilation errors

**Deployment Issues**:

- Confirm S3 bucket permissions
- Verify CloudFront distribution settings
- Check build output directory structure

## Cypress E2E Issues

**`cy.session()` not caching**:

- Check `testIsolation` is enabled in cypress.config.ts
- Verify session setup function is deterministic

**`cy.intercept()` not matching**:

- Check route pattern matches the actual request URL
- Verify HTTP method matches (GET vs POST)
- Use `cy.intercept('**/api/**')` for broad matching, then narrow down

**Flaky tests**:

- Replace `cy.wait(ms)` with `cy.wait('@alias')` using intercept aliases
- Use `.should()` assertions which auto-retry
- Add `{ timeout: 10000 }` to slow-loading element queries

## MCP Server Issues

**MCP server unavailable / not configured**:

When you need to perform an action and the relevant MCP server isn't responding or isn't configured:

1. **First, run discovery** — Use the `tool_search` tool to find any matching MCP tool (see `skills/mcp-tool-discovery.md` for the workflow). Don't assume an MCP server is missing without checking.
2. **Check `kiro-cli mcp list`** to see which servers are actually loaded for the current agent. A server may be listed but not yet booted.
3. **Verify required env vars** — Some MCP servers (`github`, `21st-dev-magic`, `figma`) need API keys in `~/.zshrc`. Missing keys = server fails silently. Re-run `./import.sh` to re-prompt.
4. **Check the agent config** — Open `~/.kiro/agents/<agent-name>.json` and confirm the MCP server is listed in `mcpServers` and not `disabled: true`.
5. **Fall back gracefully** — If a relevant MCP server genuinely doesn't exist for the operation, fall back to a CLI command. The MCP-first rule (see `steering/mcp-server-preference.md`) is "prefer MCP", not "MCP only" — `gh`, `aws`, `curl` etc. are acceptable fallbacks when no MCP tool covers the operation.

**Server timed out at startup**:

`uvx`/`npx` MCP servers download packages on first run (15-60s). Increase `mcp.noInteractiveTimeout` in `settings/cli.json` to `180000` (already set in this config).

**MCP tool name conflict / "tool not found"**:

If the agent gets `No MCP server named 'X'`, the server key may collide with Tool Search's deferred tool registration. Rename the server key to a different identifier (e.g., `sequentialthinking` instead of `sequential-thinking`).
