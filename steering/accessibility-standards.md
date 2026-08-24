---
inclusion: auto
name: accessibility-standards
description: 'WCAG 2.2 AA compliance, ARIA patterns, keyboard navigation, color contrast, screen reader support, modals/dialogs, confirmation and approval prompts (never browser alert/confirm/prompt), accessible authentication, target size, dragging alternatives. Use when building or modifying UI components, pages, forms, confirmation dialogs, login/auth flows, or approval/notification flows.'
---

# Accessibility Standards

## WCAG 2.2 AA Compliance (Required)

WCAG 2.2 became the W3C Recommendation in October 2023 and supersedes 2.1 as the current standard — it keeps everything from 2.1 AA and adds a small set of AA criteria on top. Target 2.2 AA for all new work; 2.1-only compliance is stale.

### Perceivable

- Color contrast: minimum 4.5:1 for normal text, 3:1 for large text
- Never convey information by color alone — use icons, text, or patterns
- All images have descriptive `alt` text (decorative images use `alt=""`)
- Video/audio content has captions or transcripts

### Operable

- All interactive elements reachable via keyboard (Tab, Shift+Tab, Enter, Space, Escape)
- Visible focus indicators on all focusable elements — never `outline: none` without replacement
- No keyboard traps — users can always Tab away from any component
- Skip navigation link as first focusable element on each page

### Understandable

- Form inputs have associated `<label>` elements (or `aria-label`)
- Error messages identify the field and describe the fix
- Consistent navigation and naming across pages

### Robust

- Valid semantic HTML: use `<button>` for actions, `<a>` for navigation, `<nav>`, `<main>`, `<header>`
- ARIA roles only when native HTML semantics are insufficient
- Test with screen readers (VoiceOver on macOS)
- NEVER use browser `alert()`, `confirm()`, or `prompt()` dialogs — always use a modal component (shadcn/ui Dialog or AlertDialog) instead

### New in WCAG 2.2 AA (on top of 2.1 — don't skip these)

- **Focus Not Obscured (Minimum)** — when an element receives keyboard focus, it must not be entirely hidden by other content (sticky headers/footers, cookie banners). Ensure focused elements scroll into view and aren't covered.
- **Dragging Movements** — any functionality that requires a dragging gesture (reorder lists, sliders, drag-to-dismiss) MUST have a single-pointer alternative that doesn't require dragging (e.g., up/down buttons alongside drag-to-reorder).
- **Target Size (Minimum)** — touch/click targets at least 24×24px, unless the target is inline in text, has an equivalent larger target elsewhere, or is a native control the browser/OS already sizes. (Our 44×44px mobile touch-target rule below already exceeds this — keep it; this criterion mainly affects desktop click targets that aren't otherwise covered.)
- **Consistent Help** — if a help mechanism (contact link, chat, FAQ) appears on multiple pages, keep it in the same relative order/location across the app rather than moving it around.
- **Redundant Entry** — don't make a user re-enter the same information twice in one process (e.g., shipping address again for billing) unless re-entry is essential (e.g., re-typing a password to confirm) or the previously entered value is displayed for them to reuse.
- **Accessible Authentication (Minimum)** — login/registration MUST NOT rely on a cognitive function test (e.g., solving a puzzle, remembering/transcribing something, a manually-solved math problem) as the only way to authenticate, unless an alternative is provided. Directly relevant to this repo's Cognito auth rules (`aws-standards.md`): password managers, autofill, and passkeys MUST work without interference (no blocking paste-into-password-field, no disabling browser autofill) — this is a big part of _why_ passkeys are worth offering as the optional method they already are.

## React Component Patterns

```tsx
// ✅ Accessible button
<button onClick={handleSubmit} aria-busy={isLoading} disabled={isLoading}>
  {isLoading ? 'Saving...' : 'Save Invoice'}
</button>

// ✅ Accessible form field
<label htmlFor="amount">Amount</label>
<input id="amount" type="number" aria-describedby="amount-error" aria-invalid={!!error} />
{error && <p id="amount-error" role="alert">{error}</p>}

// ✅ Accessible modal
<dialog aria-labelledby="dialog-title" aria-modal="true">
  <h2 id="dialog-title">Confirm Delete</h2>
</dialog>
```

## Testing

- Use `jest-axe` in unit tests for every component
- Use Lighthouse accessibility audits via chrome-devtools
- Test keyboard navigation in Playwright E2E tests
- Manual screen reader testing for critical flows (login, forms, navigation)

## Responsive Design

- Mobile-first approach: design for 375px, then scale up
- All pages must render correctly at four tiers: 375px (mobile/phones), 768px (tablet/small laptop), 1280px (desktop/widescreen), 1920px (TV/dashboard — kiosks, car dashboards, large displays)
- Use Tailwind responsive prefixes: `sm:`, `md:`, `lg:`, `2xl:`
- Touch targets: minimum 44x44px on mobile
- Test responsive layouts in Playwright E2E at all four breakpoints
