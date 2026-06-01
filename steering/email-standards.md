---
inclusion: auto
name: email-standards
description: Email template standards — never use default service emails (Cognito hosted, SES default). All transactional emails (account creation, verification codes, password reset, welcome, magic-link, security notifications, billing receipts) MUST be custom HTML, brand-matched, no emojis, professional, mobile-responsive, with plain-text fallback. Use when implementing email flows, Cognito email triggers, SES templates, password reset, account verification, signup, magic link, user notifications, or any user-facing email.
---

# Email Standards (MANDATORY)

Every user-facing email this system sends — account creation, email verification codes, password reset, magic-link login, welcome, security notifications, billing receipts, plan changes — MUST be a custom, brand-matched HTML email. No defaults. No quick wins. Every email is a touchpoint that should feel like part of the same product the user signed up for.

## What's Banned

- The default Cognito verification email ("Your verification code is XXXXXX" with no styling)
- The default SES "Welcome" template
- The default Amplify Auth signup/reset emails
- Plain-text-only emails when a user-facing transaction triggered them
- Emojis anywhere — subject line, preview text, headers, body. They render inconsistently across clients and feel unprofessional in transactional contexts
- Generic templates from third-party libraries shipped without brand customization
- Linking to external stylesheets (most email clients strip `<link>` and `<style>` tags)

## What's Required

### Visual Design

- **Match the brand.** Use the project's logo, primary color palette, typography, and voice. The email should feel indistinguishable from the product UI.
- **Use full color.** Primary brand color in headers, secondary color on call-to-action buttons. Don't ship monochrome emails when the brand has color.
- **No emojis.** This applies to subject lines, preview text, headers, and body — even when "everyone uses them". Use icons (inline SVG or hosted PNG) if visual punctuation is needed.
- **Mobile-responsive.** Single-column layout, max-width 600px outer container, inline CSS, touch-target-sized buttons (min 44x44px), generous padding.
- **Hierarchy.** One primary CTA per email. Make the action obvious — a colored button, not just a hyperlink in body text.

### Technical

- **Inline all CSS.** Most email clients (Outlook, Gmail's clipped view, Yahoo) strip `<style>` blocks and `<link>` tags. Run HTML through a CSS inliner (Premailer, Juice, the Mailchimp inliner) before sending, OR write inline styles directly on each element.
- **Send `multipart/alternative`** with both `text/html` and `text/plain` parts. The plain-text version is for clients that can't render HTML and for screen readers.
- **Web-safe fonts only** — Arial, Helvetica, Georgia, Times New Roman, Verdana — OR include a `@font-face` fallback. Custom web fonts work in some clients (Apple Mail, iOS Mail) but not others (Outlook desktop).
- **Logo and images:** host on a CDN (S3 + CloudFront), use absolute URLs, include `alt` text on every `<img>`, set explicit `width` and `height` to prevent layout shift. Avoid background images — Outlook strips them.
- **Test across clients.** At minimum: Gmail (web + iOS app), Outlook (desktop + web), Apple Mail (macOS + iOS), dark-mode rendering. Tools: Litmus, Email on Acid, or maintain a manual test matrix.

### Compliance

- **Physical mailing address in the footer.** Required for marketing emails by CAN-SPAM (US) and CASL (Canada), good practice for transactional too.
- **Unsubscribe link.** Required for marketing emails. Transactional emails should still link to email preferences.
- **Sender reputation.** Verify the From domain in SES, set up SPF + DKIM + DMARC records via Route53. Domain authentication is non-negotiable for production deliverability.

## Email Types To Customize (Non-Exhaustive)

| Trigger                     | Email                                               |
| --------------------------- | --------------------------------------------------- |
| User signs up               | Welcome / account-created email                     |
| Email verification (signup) | Verification code or link email                     |
| Password reset              | Reset link or code email                            |
| Passkey added to account    | "New passkey registered on \<device\>" notification |
| Login from new device       | Security notification with device + location        |
| Suspicious login attempt    | Security alert with "wasn't you?" link              |
| Magic-link login            | One-time login link email                           |
| Subscription renewed        | Billing receipt                                     |
| Plan upgrade / downgrade    | Confirmation                                        |
| Account deleted             | Confirmation + retention notice                     |
| Trial ending soon           | Reminder + upgrade CTA                              |

## AWS Implementation

### Cognito User Pool Email — Use Custom Trigger, Never the Default

Cognito's default email is plain and ugly. Wire up the `CustomEmailSender` Lambda trigger so every Cognito-initiated email (verification, reset, MFA, etc.) goes through your custom template:

```python
from aws_cdk import aws_cognito as cognito, aws_kms as kms
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime

# KMS key for the CustomEmailSender — Cognito encrypts the verification code
# with this key before passing it to your Lambda
email_key = kms.Key(self, "CognitoEmailKey", enable_key_rotation=True)

email_lambda = PythonFunction(self, "CognitoEmailHandler",
    runtime=Runtime.PYTHON_3_14,
    entry="cdk-backend/lambda/functions/cognito_email",
    index="cognito_email.py",
    environment={"KMS_KEY_ID": email_key.key_id},
)
email_key.grant_decrypt(email_lambda)

user_pool = cognito.UserPool(self, "UserPool",
    lambda_triggers=cognito.UserPoolTriggers(
        custom_email_sender=cognito.CustomEmailSender(
            function=email_lambda,
            kms_key=email_key,
        ),
    ),
    # ... rest of pool config
)
```

The Lambda receives the Cognito event, decrypts the code, builds the HTML using a templating engine (Jinja2 / Mustache), and sends via SES `send_email` or `send_raw_email`.

### SES Templates

For non-Cognito emails (welcome, billing, notifications), register reusable templates with SES:

```python
from aws_cdk import aws_ses as ses
from pathlib import Path

ses.CfnTemplate(self, "WelcomeEmailTemplate",
    template=ses.CfnTemplate.TemplateProperty(
        template_name="WelcomeEmail",
        subject_part="Welcome to {{ProductName}}",
        html_part=Path("emails/welcome.html").read_text(),
        text_part=Path("emails/welcome.txt").read_text(),
    ),
)
```

Then send with `ses.send_templated_email()` and a JSON `TemplateData` payload.

## File Layout

Store templates as source files in the project:

```
emails/
├── welcome.html              # HTML version
├── welcome.txt               # Plain-text fallback (for multipart/alternative)
├── verification.html
├── verification.txt
├── password-reset.html
├── password-reset.txt
├── login-new-device.html
├── login-new-device.txt
├── partials/
│   ├── header.html           # Shared brand header (logo, color band)
│   └── footer.html           # Shared footer (address, unsubscribe, links)
└── styles.css                # Inlined into HTML files at build time
```

The `partials/` and `styles.css` are inlined by the build step (Premailer in Python, Juice in Node) so the shipped HTML is fully self-contained.

## Templating Approach

- Templates use named placeholders: `{{user_name}}`, `{{verification_code}}`, `{{cta_url}}`, `{{product_name}}`
- Test rendering with sample data BEFORE the first production send
- Keep transactional language clear and direct — no marketing speak in security emails
- Subject lines under 50 characters when possible (mobile preview cuts at 30-40)

## Accessibility

- Body text contrast ratio ≥4.5:1, large text ≥3:1 (same as WCAG 2.1 AA — see `accessibility-standards.md`)
- Never convey information by color alone
- Semantic HTML (`<h1>`, `<p>`, `<a>`) where possible — email clients are inconsistent but it helps screen readers
- `alt` text on every `<img>`. For decorative images, `alt=""`
- Don't rely on background images (Outlook strips them, screen readers ignore them)

## Cross-References

- `aws-standards.md` — Cognito custom UI rule (same spirit: never use the defaults)
- `accessibility-standards.md` — WCAG 2.1 AA color contrast and semantic HTML
- `security-policies.md` — Secrets management for SES API keys, sender domain verification
