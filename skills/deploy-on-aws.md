---
inclusion: auto
name: deploy-on-aws
description: 'Deploy applications to AWS via deploy.sh. Triggers on phrases like: deploy to AWS, deploy.sh, build me a deploy script, host on AWS, run this on AWS, AWS architecture, estimate AWS cost, generate infrastructure. Analyzes any codebase and deploys to optimal AWS services.'
---

# Deploy on AWS

Take any application and deploy it to AWS with minimal user decisions.

## Philosophy

**Minimize cognitive burden.** User has code, wants it on AWS. Pick the most straightforward services. Don't ask questions with obvious answers.

## Workflow

1. **Analyze** - Scan codebase for framework, database, dependencies
2. **Recommend** - Select AWS services, concisely explain rationale
3. **Estimate** - Show monthly cost before proceeding
4. **Generate** - Write IaC code with security defaults applied
5. **Quality Gate** - Run the [Pre-Deployment Quality Gate from `development-workflow.md`](../steering/development-workflow.md#pre-deployment-quality-gate): lint (zero warnings), build (zero warnings), unit tests (≥90% coverage), Cypress E2E (target 100%), no deprecation notices, no critical/high vulnerabilities
6. **Deploy** - Run security checks (cdk-nag), then execute via `deploy.sh`

## Defaults

Default to **dev-sized** (cost-conscious: small instance sizes, minimal redundancy, single-AZ) unless user says "production-ready".

## MCP Server Usage (AWS Agent Toolkit)

Use the unified **AWS MCP Server** (`aws-mcp-server`, via `mcp-proxy-for-aws`) for all AWS interactions:

- **Architecture decisions**: `aws___search_documentation` (filter by `agent_skills`) and `aws___retrieve_skill` to load curated guidance before designing
- **API knowledge**: `aws___search_documentation` and `aws___suggest_aws_commands` to verify the exact API/CLI syntax — never guess
- **Cost estimates**: `aws___call_aws` to invoke Pricing API or Cost Explorer directly. **Always present costs before generating IaC** so the user can adjust before committing
- **IaC validation**: `aws___run_script` for sandboxed Python checks (e.g., synth a CDK stack and inspect the template)

## deploy.sh Contract (MANDATORY)

Every project ships a `deploy.sh` at the root following the full contract documented in `steering/aws-standards.md`. Reference template: `skills/deploy.sh.template`.

Required flags:

| Flag               | Purpose                                                                  |
| ------------------ | ------------------------------------------------------------------------ |
| `--profile <name>` | AWS profile (defaults to `default`)                                      |
| `--domain <fqdn>`  | Custom domain (saved per profile, recalled next run)                     |
| `--delete`         | Tear down stack AND deep-clean orphans (S3, log groups, ACM certs, etc.) |
| `-y` / `--yes`     | Auto-confirm — skip every prompt                                         |
| `-h` / `--help`    | Show usage                                                               |

Per-profile state lives in `.deploy-state.json` (gitignored). When the user re-runs `deploy.sh` without `--domain`, the value saved for the current profile is recalled. Add `.deploy-state.json` to `.gitignore`.

Multi-project safety: `--delete` discovers resources by the `project=<name>` tag (NOT by name prefix). Resources without that tag are never touched, so sibling projects in the same account are safe. The `CDKToolkit` bootstrap stack is never destroyed by `deploy.sh --delete`.

`-y` is intended for CI-like usage and the `master-demo` agent. Without `-y`, the script prompts at every destructive step.

### Use Agent Output Side Channels (Kiro CLI 2.3.0+)

When `deploy.sh` runs verbose tools (cdk synth, cdk deploy, npm run build), use the side channels so the **user sees full progress in the TUI** while the **agent's context stays lean** (only summary lines):

```bash
#!/usr/bin/env bash
# deploy.sh — uses Kiro CLI side channels when present
set -euo pipefail

# Detect side channels (only set when invoked by Kiro agent)
DISPLAY_OUT="${AGENT_DISPLAY_OUT:-/dev/stderr}"
CONTEXT_OUT="${AGENT_CONTEXT_OUT:-/dev/null}"

# Verbose: stream to user TUI but NOT to agent context
echo "==> cdk synth"
cdk synth --profile "$PROFILE" 2>&1 | tee "$DISPLAY_OUT" > /dev/null

echo "==> cdk deploy"
cdk deploy --all --profile "$PROFILE" --require-approval never 2>&1 | tee "$DISPLAY_OUT" > /dev/null

# Concise: summary the agent SHOULD see (via agent_notes)
STACK_NAME=$(cdk list --profile "$PROFILE" | head -1)
ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" --profile "$PROFILE" \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

cat <<EOF > "$CONTEXT_OUT"
Stack: $STACK_NAME — DEPLOYED
Profile: $PROFILE
Region: ${AWS_REGION:-us-east-1}
API endpoint: $ENDPOINT
EOF

# Plain stdout — captured normally, agent sees this too
echo "✓ Deploy complete"
```

How the channels behave:

| Channel              | User TUI | Agent context             | Use for                                                             |
| -------------------- | -------- | ------------------------- | ------------------------------------------------------------------- |
| stdout (default)     | shown    | included                  | brief summary lines (one-liners)                                    |
| `$AGENT_DISPLAY_OUT` | shown    | NOT included              | verbose logs (cdk synth, build output)                              |
| `$AGENT_CONTEXT_OUT` | shown    | included as `agent_notes` | structured facts the agent needs (stack name, endpoint URL, status) |

Always fall back gracefully: `${AGENT_DISPLAY_OUT:-/dev/stderr}` works when not invoked by Kiro.

## Principles

- Concisely explain why each service was chosen
- Always show cost estimate before generating code
- Apply security defaults automatically (encryption, private subnets, least privilege)
- Run IaC security scans (cdk-nag, cfn-nag) before deployment
- Don't ask "Lambda or Fargate?" — just pick the obvious one
- If genuinely ambiguous, then ask
- Use AWS managed KMS keys (`aws/service-name`) over customer-managed unless there's a specific compliance requirement
