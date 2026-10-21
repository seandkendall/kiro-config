---
inclusion: fileMatch
fileMatchPattern: '{cdk/**/*,**/lambda/**/*,**/*.py}'
name: aws-auth-cognito
description: 'Cognito authentication standards: custom login/registration/reset UI (never Hosted UI), custom branded emails, passkeys as an optional add-on with the post-login nudge modal, default password policy, mandatory passkey relying-party ID, API Gateway JWT auth. Use when building or reviewing Cognito auth flows.'
---

# AWS Authentication Standards (Cognito)

**Custom Login UI (MANDATORY)** - NEVER use the Cognito Hosted UI or Cognito's managed login. Always build custom pages:

- Custom **login page** — username/password MUST always be supported as the baseline sign-in method; passkey is an additional, optional method offered alongside it.
- Custom **registration page** with email verification; when the user sets a password, ALWAYS require both a **password** field and a **confirm password** field (client-side match check before submit, in addition to server-side validation).
- Custom **password reset page** (forgot password flow) — MUST be enabled and reachable from the login page in every app; not optional.
- Use the Cognito Identity SDK or `amazon-cognito-identity-js` / `@aws-amplify/auth` for all auth flows.

> **Agent Toolkit `aws-auth` skill (Cognito, added Aug 2026)** — good reference for user pool vs. identity pool selection, the `update-user-pool-client` / `set-identity-pool-roles` full-replace read-modify-write trap, PKCE vs. implicit grant, token storage/rotation, JWT authorizer wiring, passkey/WebAuthn enrollment, and threat protection. Retrieve via `aws___retrieve_skill`. **Its default recommendation is the Cognito hosted UI — that conflicts with our Custom Login UI mandate above. Our rule wins: never follow the skill's hosted-UI guidance, always build custom pages.** Use the skill for the underlying mechanics (tokens, triggers, identity pools, authorizers), not for UI delivery.

**Custom Cognito Emails (MANDATORY)** - NEVER use the default Cognito verification, password-reset, or MFA emails. Wire up the `CustomEmailSender` Lambda trigger and send brand-matched HTML via SES. Full rule: `email-standards.md`.

**Passkeys (MANDATORY)** - ALWAYS enable WebAuthn/passkeys as an optional login method — password remains the required baseline, passkey is an add-on, never a replacement:

- Passkeys MUST be available on the login page as an additional sign-in option, alongside username/password — NOT positioned as the primary or first-shown method, and NOT required for any user to sign in.
- After login, users MUST be able to add multiple passkeys from their account settings (any number of devices).
- Use Cognito's WebAuthn support with `USER_AUTH` flow and `WEB_AUTHN` challenge.
- Passkey registration: allow users to name each passkey (e.g., "MacBook Pro", "iPhone 15").
- Passkey management: list, rename, and delete registered passkeys from account settings.

**Post-Login Passkey Nudge Modal (MANDATORY)** - For any authenticated user who has NOT yet registered a passkey, show a modal after login encouraging them to add one:

- Trigger: fires once per qualifying login, only when the signed-in user has zero registered passkeys.
- Content: brief benefit explanation (faster, phishing-resistant sign-in) + a primary CTA to start passkey registration + a secondary "Maybe later" dismiss action.
- MUST include a **"Don't show this again"** checkbox — when checked and dismissed, persist that preference (per-user, e.g., a `user_preferences` attribute or DynamoDB record) so the modal never reappears for that user.
- Without the checkbox checked, a plain dismiss ("Maybe later") may re-show the modal on a subsequent login (a reasonable cadence, e.g., once per session or once per N days, is acceptable; never block the app behind this modal).
- Use shadcn/ui `Dialog` (informational + optional action — `AlertDialog` is not required here).

**Password Policy (MANDATORY — default unless told otherwise)** - Use Cognito's **default** password policy (minimum length 8, requires lowercase/uppercase/numbers/symbols) for every new user pool:

- Do NOT override `password_policy` on the `UserPool` construct unless a developer explicitly requests different rules.
- If a developer asks for different requirements, apply exactly what they specify — don't guess a "more secure" policy on your own initiative.
- This mirrors the DynamoDB-encryption and MFA defaults elsewhere in this config: omit the override, trust the service default, unless explicitly told to change it.

**Passkey Relying Party ID (MANDATORY — prevents "No relying party Id or domain configured for the user pool")** - This error means the `UserPool` construct never received a passkey relying-party (RP) ID — it has no default, so passkey auth is unusable until set explicitly:

- **Always set `passkey_relying_party_id` on the `UserPool` construct** — set it to the domain your app authenticates from:
  ```python
  cognito.UserPool(self, "UserPool",
      passkey_relying_party_id="auth.example.com",       # your user pool domain or custom domain
      passkey_user_verification=cognito.PasskeyUserVerification.PREFERRED,
      sign_in_policy=cognito.SignInPolicy(
          allowed_first_auth_factors=cognito.AllowedFirstAuthFactors(password=True, passkey=True),
      ),
      # ... rest of pool config
  )
  ```
- **If the user pool has a custom domain**, the RP ID **must** be the fully-qualified custom domain, not the Cognito-assigned prefix domain — a mismatch silently breaks passkey auth for the prefix domain even after RP ID is set. If both must keep working, set RP ID to the prefix domain instead.
- **Do this at initial pool creation, not as an afterthought** — the error only surfaces at registration/sign-in time, not at `cdk synth`/`deploy` time.
- **Verify the fix**: `aws cognito-idp get-user-pool-mfa-config --user-pool-id <id>` (via `aws-mcp-server`) should return `WebAuthnConfiguration.RelyingPartyId` matching your domain.

**API Gateway Integration** - Configure Bearer token auth with JWT validation.
