---
inclusion: auto
name: accessibility-standards
description: 'WCAG 2.1 AA compliance, ARIA patterns, keyboard navigation, color contrast, screen reader support, modals/dialogs, confirmation and approval prompts (never browser alert/confirm/prompt). Use when building or modifying UI components, pages, forms, confirmation dialogs, or approval/notification flows.'
---

# Accessibility Standards

## WCAG 2.1 AA Compliance (Required)

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
- All pages must render correctly at: 375px (mobile), 768px (tablet), 1280px (desktop)
- Use Tailwind responsive prefixes: `sm:`, `md:`, `lg:`
- Touch targets: minimum 44x44px on mobile
- Test responsive layouts in Playwright E2E at all three breakpoints
