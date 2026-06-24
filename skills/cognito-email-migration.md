---
name: cognito-email-migration
description: Runbook for migrating an existing Cognito User Pool from default emails to a custom CustomEmailSender Lambda. Use when an existing app needs to switch from the default Cognito verification / password-reset / MFA emails to brand-matched HTML emails sent via SES.
---

# Cognito Email Migration

Step-by-step runbook for replacing the default Cognito email sender on an existing User Pool with a custom `CustomEmailSender` Lambda trigger. For NEW apps, just include the trigger from day one — this runbook is for existing pools that already have users.

## Pre-flight

Before starting, confirm:

- The Cognito User Pool exists and is currently using the default Cognito email service (or SES with a non-templated `from_email_address` that you want to upgrade)
- You have CDK deployment access to the stack that owns the User Pool
- The `From:` domain you'll send from is verified in SES (with SPF + DKIM + DMARC published per `email-standards.md`)
- You have a non-production environment (dev / staging) that mirrors production — DO NOT migrate prod first
- You've reviewed `email-standards.md` and `email-template-rendering.md`

## Important Caveat

Once `CustomEmailSender` is enabled on a User Pool, ALL Cognito-initiated emails go through your Lambda. There is no "fallback to default Cognito" if the Lambda fails. A Lambda timeout, KMS-decrypt failure, or SES send error means the email never arrives, which means new sign-ups can't verify and existing users can't reset passwords.

This is a one-way door for the duration the trigger is enabled. Bake in:

- CloudWatch alarms on Lambda errors and DLQ depth
- A configured DLQ on the Lambda (so failures are recoverable, not lost)
- Synthetic monitoring (a scheduled test signup once per hour against a throwaway email)
- A documented rollback plan (remove the trigger via `cdk deploy`) — see "Rollback" below

## Migration Steps

### 1. Generate the email assets in the existing project

Copy from `skills/email-templates/`:

- `welcome.html` + `welcome.txt`
- `verification.html` + `verification.txt`
- `password-reset.html` + `password-reset.txt`

Customize the placeholders to match your brand (logo URL, primary color, accent color, mailing address). Place them in `cdk-backend/lambda/functions/cognito_email/emails/`.

Build them through the CSS inliner per `email-template-rendering.md` so the shipped HTML has no `<style>` blocks.

### 2. Add the Lambda handler

Copy `skills/email-templates/cognito-email-handler.py` to `cdk-backend/lambda/functions/cognito_email/cognito_email.py`. Add `requirements.txt`:

```
aws-encryption-sdk==4.0.1
jinja2==3.1.4
boto3==1.43.36
```

(Pin to the latest stable versions at migration time; check `pip index versions <pkg>` for current.)

### 3. Add the KMS key + Lambda + trigger to the existing CDK stack

Open the stack file that defines the User Pool. Add the following imports + resources:

```python
from aws_cdk import aws_kms as kms, aws_iam as iam
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime, Tracing
from aws_cdk.aws_sqs import Queue

# 1. KMS key for Cognito to encrypt verification codes
email_key = kms.Key(self, "CognitoEmailKey",
    enable_key_rotation=True,
    description="Encrypts Cognito verification codes for CustomEmailSender Lambda",
)

# 2. DLQ for failed email sends
email_dlq = Queue(self, "CognitoEmailDlq",
    retention_period=Duration.days(14),
)

# 3. Lambda handler
email_lambda = PythonFunction(self, "CognitoEmailHandler",
    runtime=Runtime.PYTHON_3_14,
    entry="cdk-backend/lambda/functions/cognito_email",
    index="cognito_email.py",
    timeout=Duration.seconds(10),
    memory_size=512,
    dead_letter_queue=email_dlq,
    environment={
        "KMS_KEY_ID": email_key.key_id,
        "SES_FROM_ADDRESS": "no-reply@yourdomain.com",
        "SES_CONFIG_SET": "default",
        "PRODUCT_NAME": "Acme",
        "PRIMARY_COLOR": "#1a73e8",
        "ACCENT_COLOR": "#f0f6ff",
        "LOGO_URL": "https://cdn.yourdomain.com/logo.png",
        "SUPPORT_EMAIL": "support@yourdomain.com",
        "COMPANY_ADDRESS": "Acme Inc., 123 Example St, Calgary, AB",
        "UNSUBSCRIBE_URL": "https://app.yourdomain.com/preferences",
    },
)
email_key.grant_decrypt(email_lambda)
email_lambda.add_to_role_policy(iam.PolicyStatement(
    actions=["ses:SendEmail", "ses:SendRawEmail"],
    resources=["*"],  # tighten to specific identity ARNs in production
))

# 4. Wire to existing UserPool — modify the existing UserPool construct
# IMPORTANT: this modifies the EXISTING UserPool, not a new one
user_pool.add_trigger(
    cognito.UserPoolOperation.CUSTOM_EMAIL_SENDER,
    email_lambda,
)
```

If you originally constructed the User Pool inline with `lambda_triggers=cognito.UserPoolTriggers(...)`, you instead update that block:

```python
user_pool = cognito.UserPool(self, "UserPool",
    # ... existing config ...
    lambda_triggers=cognito.UserPoolTriggers(
        # ... any existing triggers ...
        custom_email_sender=cognito.CustomEmailSender(
            function=email_lambda,
            kms_key=email_key,
        ),
    ),
)
```

### 4. Run cdk diff and review the change

```bash
cd cdk-backend
cdk diff --profile dev
```

Expect the diff to include:

- New `AWS::KMS::Key` for the email key
- New `AWS::SQS::Queue` for the DLQ
- New `AWS::Lambda::Function` for the handler
- Update to `AWS::Cognito::UserPool` adding the `LambdaConfig.CustomEmailSender` field
- New IAM role + permissions

The User Pool update is a non-replacing CFN UPDATE — your existing users are not affected.

### 5. Deploy to non-prod first

```bash
./deploy.sh --profile dev -y
```

After deploy, watch CloudWatch Logs for the new Lambda:

```bash
aws logs tail /aws/lambda/CognitoEmailHandler --follow --profile dev
```

### 6. Test the flow end-to-end in non-prod

Run through every Cognito-triggered email path:

- **Sign up** a new user via your app's registration UI → expect the new HTML verification email
- **Resend verification code** → expect the new HTML email
- **Forgot password** → expect the new HTML password-reset email
- **Login from new device** (if AccountTakeOverNotification is enabled) → expect the new security alert email
- **Admin-create user** (via Cognito console → Users → Create user) → expect the new welcome email

For each, verify:

- HTML renders correctly in Gmail (web + iOS), Outlook (desktop + web), Apple Mail
- Plain-text alternative is present (`Show original` in Gmail to confirm `multipart/alternative`)
- Links work
- Subject + preheader read sensibly in inbox preview
- The verification code displayed in the email matches the one Cognito's API confirms

### 7. Monitor for 24-48 hours in non-prod

Track:

- `aws/lambda/CognitoEmailHandler` Errors metric → must be 0
- DLQ depth → must be 0
- SES Bounce rate → check the SES configuration set's bounce/complaint metrics
- Synthetic test pass rate (your scheduled test signup)

If anything looks off, fix in non-prod before touching production.

### 8. Roll forward to production

Once non-prod is clean for 24-48 hours, deploy the same change to prod:

```bash
./deploy.sh --profile prod -y
```

Same monitoring for the first 24 hours post-deploy. Have the rollback plan ready.

## Rollback

If production starts failing (Lambda errors, SES throttling, KMS issues, DLQ filling up):

1. **Immediately** revert the User Pool trigger by removing the `add_trigger` call (or the `custom_email_sender=...` field) from the stack code
2. Run `./deploy.sh --profile prod -y` to push the rollback through CFN
3. Cognito will resume using its default email service for new triggers — verification, password-reset, etc. will go back to the plain default emails until you fix the Lambda

Existing in-flight verification codes (issued while the Lambda was failing) are lost — affected users will need to request a new code. Surface this in your support runbook.

## Cleanup

Once the migration is stable in production for a week:

- Remove any old `from_email_address` config on the User Pool that pointed at SES with a different template approach
- Delete any unused SES `CfnTemplate` resources from the previous email pipeline
- Remove any old templating Lambda or Step Function pipeline that's been superseded

## Cross-References

- `steering/email-standards.md` — what the new emails must look like
- `skills/email-template-rendering.md` — CSS inlining build pipeline
- `skills/email-templates/cognito-email-handler.py` — reference Lambda implementation
- `skills/email-templates/{welcome,verification,password-reset}.{html,txt}` — starter templates
- `steering/aws-standards.md` — Cognito custom UI rule (companion to custom emails)
