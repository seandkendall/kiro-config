---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
name: aws-deploy-contract
description: 'deploy.sh is the only deployment mechanism: the exact flag contract (--profile, --domain, --delete, -y, -h), per-profile state persistence, deep-cleanup-on-delete, auto-confirm behavior, multi-project safety in shared AWS accounts. Use when writing, reviewing, or running a project deploy.sh.'
---

# AWS Deployment Contract (deploy.sh)

**Infrastructure as Code** - All changes via CDK code, React code, and the `deploy.sh` script.

**`deploy.sh` is the ONLY supported deployment mechanism** - Never deploy via `cdk deploy` directly, the AWS Console, or any other path.

Every project MUST have a `deploy.sh` script at the project root that follows this exact contract:

#### Required Flags

| Flag               | Required                         | Purpose                                                    |
| ------------------ | --------------------------------- | ----------------------------------------------------------- |
| `--profile <name>` | Optional (defaults to `default`) | AWS profile to use                                          |
| `--domain <fqdn>`  | Optional                         | Custom domain for the deployment (e.g. `app.example.com`)   |
| `--delete`         | Optional                         | Tear down the stack AND deep-clean associated resources     |
| `-y` / `--yes`     | Optional                         | Auto-confirm — skip every interactive prompt (deletes too)  |
| `-h` / `--help`    | Optional                         | Show usage                                                   |

Examples:

```bash
./deploy.sh                                        # Uses default profile + last-saved domain (if any)
./deploy.sh --domain d1.example.com                # Saves d1 against the default profile
./deploy.sh --domain d2.example.ca --profile work  # Saves d2 against the 'work' profile
./deploy.sh --profile work                          # Reuses d2 (saved earlier)
./deploy.sh --delete                                # Tears down with confirmation prompt
./deploy.sh --delete -y                             # Tears down without prompting
```

#### Per-profile State (MANDATORY)

`deploy.sh` MUST persist non-profile inputs (currently `--domain`, plus any future named flags) keyed by AWS profile, so subsequent runs auto-fill them.

- Storage: `.deploy-state.json` at the project root, gitignored.
- Format: a JSON object keyed by profile name, value is an object of saved inputs.
- Special-case: when no `--profile` is passed, the key is the literal string `default`.
- Read order on each run: CLI flag → saved state for that profile → error if neither and the value is required.
- Write: every successful invocation that received a non-profile flag MUST update the saved value for that profile before exiting.
- Add `.deploy-state.json` to the project's `.gitignore` — it can leak deployment topology across forks.

Example:

```json
{
  "default": { "domain": "d1.example.com" },
  "work": { "domain": "d2.example.ca" },
  "demo": { "domain": "demo.kiro.dev" }
}
```

#### Deep-Cleanup on `--delete` (MANDATORY)

`cdk destroy` leaves orphans. `deploy.sh --delete` MUST go further:

- Empty and delete every S3 bucket created by the stack (CDK won't delete non-empty buckets even with `RemovalPolicy.DESTROY`)
- Delete every CloudWatch log group created by the stack
- Remove DNS records the stack added to a shared Route53 hosted zone (without deleting the zone itself — see "Multi-Project Safety" below)
- Delete ACM certificates created exclusively for this stack
- Delete any SQS queues, SNS topics, EventBridge rules, ECR repos the stack owns
- Detach and delete IAM roles + policies the stack created
- Wait for `DELETE_COMPLETE` before exiting; surface any `DELETE_FAILED` resources clearly

Tag-based discovery is the safest sweep — every stack tags resources with `project=<name>` (the same tag the stack's AWS Resource Group is built on, see `aws-cdk-core.md`).

#### `-y` Auto-Confirm Flag (MANDATORY)

When `-y` is set, the script MUST NOT issue any interactive prompts — including the destroy confirmation, `cdk deploy --require-approval never`, and any safety `read -p` prompts. Without `-y`, the script SHOULD prompt at every destructive step.

#### Multi-Project Safety in Shared AWS Accounts (MANDATORY)

The same AWS account often hosts multiple projects sharing infrastructure (Route53 zones, ACM certs, VPCs, Cognito pools). `deploy.sh` MUST NOT break sibling projects:

- **Discover by tag, and by CloudFormation stack, not by name pattern.** Use the `project=<name>` tag or the stack's own CFN resource listing. Never delete resources matching a name prefix or substring.
- **Touch shared zones surgically** — delete only the records this stack added (by `name` + `type`). Never delete the hosted zone itself unless this stack owns it end-to-end.
- **Pre-flight check on `--delete`** — list all resources tagged with this project's tag and show them to the user (or skip under `-y`). Untagged resources are NEVER touched.
- **Shared certificates** — ACM certs in `us-east-1` are commonly reused (CloudFront requires certs there). If imported by another stack, never delete it on teardown, even if imported via `Certificate.fromCertificateArn`.
- **CDK bootstrap stack** — `CDKToolkit` is shared across all CDK projects in the account. Never destroy it from `deploy.sh --delete`.

The script handles: `cdk synth`, `cdk diff`, `cdk deploy`, frontend build + S3 sync, CloudFront invalidation, post-deploy state save. Reference template: `skills/deploy-on-aws/references/deploy.sh.template`.

Never make manual changes in AWS Console.

**No Hardcoded Values (default)** - Prefer SSM Parameter Store (`SecureString` for secrets) by default; use AWS Secrets Manager only when rotation, RDS/Aurora credentials, or an AWS service integration requires it (see `security-policies.md`). Environment variables are for non-secret config only. **Exception:** in a private, single-owner repo, the user may opt into committing plaintext secrets/config — honor it per `security-policies.md` → "Committing Secrets in Private Repos".

**Post-Deployment Testing** - Always:

1. Execute live tests against deployed endpoints
2. Verify expected responses and status codes
3. Check application logs for errors
