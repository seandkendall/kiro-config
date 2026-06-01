---
name: email-template-rendering
description: Build pipelines for email templates — CSS inlining, Jinja2/Mustache/MJML rendering, plain-text alternatives, cross-client testing. Use when implementing the build step for transactional email templates following email-standards.md.
---

# Email Template Rendering

Companion skill to `steering/email-standards.md`. Covers the build pipeline: how to take source HTML templates with `<style>` blocks and external partials, and produce send-ready emails with all CSS inlined.

## Why You Need a Build Step

Most email clients (Outlook, Gmail clipped view, Yahoo) strip `<link>` and `<style>` tags from `<head>`. If your template has `<style>` blocks, the styles WILL be ignored by some clients. The fix is to inline every style as `style="..."` attributes on the elements themselves before sending.

You don't write inline CSS by hand. You author readable templates with `<style>` blocks and `{{ placeholders }}`, then run them through an inliner.

## Tooling Options

| Tool                | Language | Best for                         | Notes                                                                          |
| ------------------- | -------- | -------------------------------- | ------------------------------------------------------------------------------ |
| **Premailer**       | Python   | Python projects, Lambda handlers | Pure Python, parses CSS and inlines styles. `pip install premailer`            |
| **Juice**           | Node     | Node projects, build-time inline | Battle-tested, large user base. `npm install juice`                            |
| **Maizzle**         | Node     | Tailwind-CSS-style email auth    | Full pipeline (templates → MJML → inline). Heavier, more powerful              |
| **MJML**            | Node CLI | Component-based emails           | Compiles MJML markup → responsive HTML → inline. Excellent for complex layouts |
| **AWS SES inliner** | n/a      | Doesn't exist                    | SES does NOT inline CSS for you. You must inline before calling `send_email`.  |

For most projects deployed via this config: **Premailer (Python) for Lambda handlers, Juice (Node) for frontend build pipelines**.

## Templating Engines

| Engine               | When to use                                                                                                      | Syntax                                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Jinja2**           | Python Lambda handlers (e.g., Cognito CustomEmailSender). Default choice.                                        | `{{ user_name }}`, `{% if %}`, `{% for %}`               |
| **Mustache**         | Logic-less templates shared across Python + Node + frontend                                                      | `{{ user_name }}`, `{{#section}}`                        |
| **MJML**             | Complex multi-section emails (newsletters, plan upgrades) where you'd otherwise hand-write deeply nested tables  | `<mj-section>`, `<mj-button>` (compiles to inlined HTML) |
| **SES TemplateData** | Pre-registered SES templates invoked via `send_templated_email`. Limited to `{{ name }}` substitution (no logic) | `{{ name }}` only                                        |

### Decision

- **Cognito CustomEmailSender** → Jinja2 (Python, in-Lambda render)
- **Welcome / billing / account notifications** → Jinja2 in Lambda OR pre-registered SES `CfnTemplate` with `TemplateData` JSON
- **Marketing / newsletters** → MJML (build-time compile, not runtime — store the compiled HTML as the template)

## Build Pipeline (Python / Lambda)

```python
# build_emails.py — run this before packaging the Lambda
from pathlib import Path
from premailer import transform

SOURCE_DIR = Path("emails/src")     # authored templates with <style> blocks
OUTPUT_DIR = Path("emails")         # inlined templates the Lambda loads at runtime

OUTPUT_DIR.mkdir(exist_ok=True)

for source in SOURCE_DIR.glob("*.html"):
    html = source.read_text()
    inlined = transform(
        html,
        keep_style_tags=False,           # remove <style> blocks after inlining
        remove_classes=False,            # keep class names for any client that DOES support them
        strip_important=False,           # keep !important — critical for Outlook overrides
        cssutils_logging_level="ERROR",  # suppress noisy parser warnings
    )
    (OUTPUT_DIR / source.name).write_text(inlined)
    print(f"  inlined: {source.name}")
```

Wire this into `deploy.sh` before `cdk deploy`:

```bash
echo "==> Inlining email templates"
python3 -m pip install --quiet premailer
python3 build_emails.py
```

## Build Pipeline (Node / frontend)

```javascript
// build-emails.mjs
import { readdirSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import juice from 'juice';

const SRC = 'emails/src';
const OUT = 'emails';
mkdirSync(OUT, { recursive: true });

for (const file of readdirSync(SRC)) {
  if (!file.endsWith('.html')) continue;
  const html = readFileSync(join(SRC, file), 'utf8');
  const inlined = juice(html, { removeStyleTags: true });
  writeFileSync(join(OUT, file), inlined);
  console.log(`  inlined: ${file}`);
}
```

Add to `package.json`:

```json
{
  "scripts": {
    "build:emails": "node build-emails.mjs"
  }
}
```

## Plain-Text Alternative (MANDATORY)

Every HTML template MUST have a matching `.txt` companion. Author by hand — automated HTML→text converters produce poor output for emails. Keep the structure flat:

```
Welcome to {{ product_name }}.

Hi {{ user_name }},

Thanks for signing up. Your account is ready.

Open your dashboard: {{ cta_url }}

Need help? Email {{ support_email }}.

---
{{ company_address }}
Email preferences: {{ unsubscribe_url }}
```

When sending, set BOTH parts:

```python
ses.send_email(
    Source=from_address,
    Destination={"ToAddresses": [recipient]},
    Message={
        "Subject": {"Data": subject},
        "Body": {
            "Html": {"Data": html_body},
            "Text": {"Data": text_body},
        },
    },
)
```

SES sends as `multipart/alternative` automatically when both `Html` and `Text` are present.

## Cross-Client Testing

Before going live, test the rendered HTML against real clients. Two approaches:

1. **Manual matrix** — send the email to test accounts on Gmail (web + iOS app), Outlook (desktop + web), Apple Mail (macOS + iOS). Spot-check dark mode. Check the inbox preview text.
2. **Automated** — paid services that render against 50+ clients:
   - [Litmus](https://www.litmus.com/) — industry standard, expensive
   - [Email on Acid](https://www.emailonacid.com/) — comparable, slightly cheaper
   - [Mailtrap](https://mailtrap.io/) — free tier with screenshot previews, fewer clients

For demos and most production projects, the manual matrix is enough. Use Litmus / Email on Acid when launching a brand-critical email flow.

## Local Preview During Development

Run a quick local render to verify a template before deploying:

```python
# preview.py
from jinja2 import Environment, FileSystemLoader
from premailer import transform

env = Environment(loader=FileSystemLoader("emails/src"))
html = env.get_template("welcome.html").render(
    product_name="Acme",
    user_name="Alex",
    primary_color="#1a73e8",
    accent_color="#f0f6ff",
    logo_url="https://placehold.co/140x32/1a73e8/ffffff?text=Acme",
    cta_url="https://app.acme.com/dashboard",
    support_email="support@acme.com",
    company_address="Acme Inc., 123 Example St, Calgary, AB",
    unsubscribe_url="https://app.acme.com/preferences",
)
inlined = transform(html, keep_style_tags=False)
open("preview.html", "w").write(inlined)
print("Open preview.html in a browser to inspect.")
```

## Anti-Patterns

- **Don't** ship the source template (with `<style>` block) directly. Run it through the inliner.
- **Don't** rely on `<link rel="stylesheet">`. It's stripped by most clients.
- **Don't** auto-convert HTML to plain text. Author the `.txt` version separately for readability.
- **Don't** skip the build step "because Gmail handles it" — Outlook and Yahoo don't.
- **Don't** use CSS Grid, Flexbox, or modern selectors. Stick to `<table>` layout for compatibility.
- **Don't** include `<script>` tags. Clients strip them and may flag the email as spam.

## Cross-References

- `steering/email-standards.md` — what to ship (banned defaults, brand match, no emojis)
- `skills/email-templates/welcome.html` — sample brand-matched template
- `skills/email-templates/cognito-email-handler.py` — sample Cognito CustomEmailSender Lambda
