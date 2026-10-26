---
inclusion: auto
name: email-standards
description: 'Email template standards — never use default service emails (Cognito hosted, SES default). All transactional emails (account creation, verification codes, password reset, welcome, magic-link, security notifications, billing receipts) MUST be custom HTML, brand-matched, no emojis, professional, mobile-responsive, with plain-text fallback. Use when implementing email flows, Cognito email triggers, SES templates, password reset, account verification, signup, magic link, user notifications, or any user-facing email.'
---

# Email Standards (MANDATORY)

**The rule in one sentence:** every email this system sends to a real user MUST be a custom, brand-matched HTML email that this project built — never an email a service (Cognito, SES, Amplify) generates and sends automatically using its own built-in template.

This applies to every user-facing email: account creation, email verification codes, password reset, magic-link login, welcome, security notifications, billing receipts, plan changes. Every one of these is a touchpoint that should feel like part of the same product the user signed up for — not a plain, unstyled system notice.

## What's Banned

Don't let the underlying AWS service send its own default email — if about to enable one of these without wiring a custom Lambda/template, stop and build the custom version instead:

- The default Cognito verification/reset/MFA email, SES "Welcome" template, Amplify Auth signup/reset emails
- Plain-text-only emails on a user-facing transaction
- Emojis anywhere (subject, preview text, headers, body) — inconsistent rendering across clients, unprofessional in transactional contexts
- Generic third-party templates shipped without brand customization
- External stylesheets via `<link>`/`<style>` (most clients strip them)

## What's Required

### Visual Design

- **Match the brand** — logo, primary color palette, typography, voice; the email should feel indistinguishable from the product UI. Use full color (don't ship monochrome when the brand has color).
- **No emojis**, anywhere, even "everyone uses them" — use icons (inline SVG/hosted PNG) for visual punctuation.
- **Mobile-responsive** — single-column, max-width 600px, inline CSS, touch targets ≥44×44px, generous padding.
- **One primary CTA** per email — a colored button, not a hyperlink in body text.

### Technical

- **Inline all CSS.** Most clients (Outlook, Gmail's clipped view, Yahoo) strip `<style>` blocks and `<link>` tags — run HTML through a CSS inliner (Premailer, Juice) before sending.
- **Send MIME `multipart/alternative`** with both `text/html` and `text/plain` parts (the plain-text part serves clients that can't render HTML and screen readers).
- **Web-safe fonts only** — Arial, Helvetica, Georgia, Times New Roman, Verdana — OR a `@font-face` fallback (custom web fonts work in some clients but not Outlook desktop).
- **Logo and images:** host on a CDN (S3 + CloudFront), absolute URLs, `alt` text on every `<img>`, explicit `width`/`height`. Avoid background images — Outlook strips them.
- **Test across clients**: Gmail (web + iOS), Outlook (desktop + web), Apple Mail (macOS + iOS), dark-mode rendering. Tools: Litmus, Email on Acid, or a manual test matrix.

### Compliance

- **Physical mailing address in the footer** and **unsubscribe link** — required for marketing emails under **CAN-SPAM** (US) and **CASL** (Canada); good practice on transactional too (link to preferences instead of unsubscribe).
- **Sender reputation.** Verify the From domain in SES, set up SPF + DKIM + DMARC records via Route53. Domain authentication is non-negotiable for production deliverability.

## Email Types To Customize (Non-Exhaustive)

Signup/welcome, email verification code, password reset, passkey-added notification, new-device login, suspicious-login alert, magic-link login, billing receipt, plan upgrade/downgrade confirmation, account-deleted confirmation, trial-ending reminder.

## AWS Implementation

### Cognito User Pool Email — Use Custom Trigger, Never the Default

Cognito's default email is plain and ugly. Wire up the `CustomEmailSender` Lambda trigger so every Cognito-initiated email (verification, reset, MFA, etc.) goes through your custom template:

```python
from aws_cdk import aws_cognito as cognito, aws_kms as kms
from aws_cdk.aws_lambda_python_alpha import PythonFunction
from aws_cdk.aws_lambda import Runtime

email_key = kms.Key(self, "CognitoEmailKey", enable_key_rotation=True)  # Cognito encrypts the code with this before passing it to your Lambda

email_lambda = PythonFunction(self, "CognitoEmailHandler",
    runtime=Runtime.PYTHON_3_14,
    entry="cdk-backend/lambda/functions/cognito_email",
    index="cognito_email.py",
    environment={"KMS_KEY_ID": email_key.key_id},
)
email_key.grant_decrypt(email_lambda)

user_pool = cognito.UserPool(self, "UserPool",
    lambda_triggers=cognito.UserPoolTriggers(
        custom_email_sender=cognito.CustomEmailSender(function=email_lambda, kms_key=email_key),
    ),
    # ... rest of pool config
)
```

The Lambda decrypts the code, builds HTML via a templating engine (Jinja2/Mustache), and sends via SES `send_email`/`send_raw_email`.

### SES Templates

For non-Cognito emails (welcome, billing, notifications), register reusable templates with SES. `aws_cdk.aws_ses` has no L2 construct for templates as of this writing — `CfnTemplate` is the correct current choice, not a stopgap:

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

Send with `ses.send_templated_email()` and a JSON `TemplateData` payload.

## File Layout

Store templates as source files: `emails/<type>.html` + `.txt` (plain-text fallback) per type, shared `emails/partials/header.html` + `footer.html`, and `emails/styles.css` inlined into the HTML at build time (Premailer in Python, Juice in Node) so the shipped HTML is fully self-contained.

## Templating Approach

- Named placeholders: `{{user_name}}`, `{{verification_code}}`, `{{cta_url}}`, `{{product_name}}`
- Test rendering with sample data BEFORE the first production send
- Keep transactional language clear and direct — no marketing speak in security emails

## Accessibility

Follow **WCAG 2.1 AA** (see `accessibility-standards.md`): contrast ≥4.5:1 body / ≥3:1 large text, never convey information by color alone, semantic HTML (`<h1>`, `<p>`, `<a>`) where email clients allow it, `alt` text on every `<img>` (`alt=""` for decorative), no background images (Outlook strips them, screen readers ignore them).

## Email Checklist (RUN BEFORE EVERY GO-LIVE)

Before shipping any new transactional email:

1. Not a Cognito / SES / Amplify default template. No emojis anywhere (subject, preheader, headers, body).
2. Brand match: logo, colors, typography consistent with product UI.
3. Subject ≤50 chars (mobile truncates at 30-40); preheader present (50-100 char hidden preview).
4. Single primary CTA (one colored button, not competing links); touch targets ≥44×44px.
5. CSS inlined (no `<style>` blocks remain); plain-text alternative sent as `multipart/alternative`.
6. Web-safe fonts with fallback stack, or `@font-face` with fallback.
7. Every `<img>` has `alt` text + explicit `width`/`height`; no background images; no `<script>` tags.
8. Color contrast ≥4.5:1 (WCAG 2.1 AA — see `accessibility-standards.md`).
9. CAN-SPAM/CASL footer requirements met (mailing address, unsubscribe/preferences link).
10. From-domain verified in SES with SPF + DKIM + DMARC published.
11. Cross-client preview passes (Gmail web+iOS, Outlook desktop+web, Apple Mail) including dark mode.
12. Subject + preheader read sensibly together; test send to a real account confirms delivery + threading (not just a render preview).

If any item fails, fix before sending the first production email.

## Templating Engines

For the rendering build pipeline (CSS inlining, build steps, runtime rendering), see the companion skill: **`skills/email-template-rendering/SKILL.md`**.

| Engine | When to use |
| --- | --- |
| **Jinja2** | Python Lambda handlers (e.g., Cognito `CustomEmailSender`). Default for runtime rendering. |
| **Mustache** | Logic-less templates rendering in BOTH Python and Node from one source. |
| **MJML** | Complex multi-section emails (newsletters, plan upgrades) — compiles to responsive HTML at build time. |
| **SES `TemplateData`** | Pre-registered SES templates via `send_templated_email` — `{{ name }}` substitution only, no logic. |

Decision rules: Cognito-driven emails → Jinja2 in the `CustomEmailSender` Lambda. App-driven transactional (welcome, billing, security alerts) → Jinja2 in Lambda or pre-registered SES `CfnTemplate`. Marketing/newsletter → MJML compiled at build time, registered as SES templates.

## Cross-References

- `aws-auth-cognito.md` — Cognito custom UI rule (same spirit: never use the defaults)
- `accessibility-standards.md` — WCAG 2.1 AA color contrast and semantic HTML
- `security-policies.md` — Secrets management for SES API keys, sender domain verification

> **Agent Toolkit AWS End User Messaging / SES skills (added Sep 2026)** — cover SMS/RCS, WhatsApp, and SES sending-identity/production-access verification. Retrieve via `aws___retrieve_skill` per `aws-agent-toolkit.md` if a project needs multi-channel notifications or SES sandbox exit — this repo has no multi-channel usage yet. **These skills don't override the mandatory custom-template rule above** — they cover account/channel setup, not template content.
