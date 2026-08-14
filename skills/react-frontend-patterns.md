---
name: react-frontend-patterns
description: React 19+, TypeScript, Tailwind CSS, shadcn/ui component patterns, accessibility, forms, state management. Use when building or reviewing React components, pages, or frontend architecture.
---

# React Frontend Patterns

## Component Template

```tsx
/** Dashboard page — displays financial overview with charts and recent transactions. */
interface DashboardProps {
  userId: string;
}

export function Dashboard({ userId }: DashboardProps) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['dashboard', userId],
    queryFn: fetchDashboard,
  });

  if (isLoading) return <DashboardSkeleton />;
  if (error) return <ErrorState message="Failed to load dashboard" />;
  if (!data) return <EmptyState message="No data yet" />;

  return (
    <main data-testid="dashboard-page">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      {/* content */}
    </main>
  );
}
```

## Form Pattern (react-hook-form + zod)

```tsx
const schema = z.object({
  amount: z.number().positive('Must be greater than 0'),
  description: z.string().min(1, 'Required'),
});

function TransactionForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({ resolver: zodResolver(schema) });
  return (
    <form onSubmit={handleSubmit(onSubmit)} data-testid="transaction-form">
      <label htmlFor="amount">Amount</label>
      <input
        id="amount"
        type="number"
        aria-invalid={!!errors.amount}
        aria-describedby="amount-error"
        {...register('amount', { valueAsNumber: true })}
      />
      {errors.amount && (
        <p id="amount-error" role="alert">
          {errors.amount.message}
        </p>
      )}
    </form>
  );
}
```

## State Management

- Server state: TanStack Query (useQuery, useMutation, optimistic updates)
- Client state: Zustand for global UI state, React Context for theme/auth
- Never prop-drill more than 2 levels

## Accessibility Checklist

- All interactive elements keyboard-reachable (Tab, Enter, Space, Escape)
- Visible focus indicators — never `outline: none` without replacement
- Color contrast: 4.5:1 normal text, 3:1 large text
- All images have `alt` text (decorative: `alt=""`)
- Form inputs have `<label>` or `aria-label`
- Error messages use `role="alert"`
- NEVER use browser `alert()`, `confirm()`, or `prompt()` dialogs — for ANY purpose: informational messages, error/success notifications, confirmations, or approval prompts. Always use a modal component instead (shadcn/ui `Dialog` for messages/notifications, `AlertDialog` for confirmations/approvals that block on a user decision)

## Responsive Breakpoints

- Mobile: 375px (default, mobile-first)
- Tablet: `md:` (768px)
- Desktop: `lg:` (1280px)
- Touch targets: minimum 44x44px on mobile

## data-testid Selectors (MANDATORY — for Playwright)

`data-testid` attributes are **REQUIRED** on every interactive element. Playwright tests are non-negotiable in this codebase, and CSS/class selectors break tests when styles change.

**Required on:**

- Every `<button>` / `<a>` (clickable)
- Every `<input>` / `<select>` / `<textarea>` (user input)
- Every `<form>` (submission target)
- Every page-level container (test entry point)
- Every error/success message (assertion target)
- Every modal / dialog (visibility check)
- Every loading indicator (race-condition guard)

**Naming pattern:** `data-testid="<entity>-<action>"` or `data-testid="<entity>-<role>"`

| Element        | Pattern                  | Example                              |
| -------------- | ------------------------ | ------------------------------------ |
| Submit button  | `<entity>-submit`        | `data-testid="invoice-submit"`       |
| Cancel button  | `<entity>-cancel`        | `data-testid="invoice-cancel"`       |
| Form input     | `<entity>-<field>-input` | `data-testid="invoice-amount-input"` |
| Error message  | `<entity>-error`         | `data-testid="invoice-error"`        |
| Page container | `<page>-page`            | `data-testid="dashboard-page"`       |
| List item      | `<entity>-row-<id>`      | `data-testid="invoice-row-123"`      |
| Modal          | `<entity>-modal`         | `data-testid="delete-confirm-modal"` |

**Rules:**

- Never use class selectors, IDs, or tag selectors in Playwright — `page.getByTestId('...')` only
- Keep selectors **stable** — only change them when the element's purpose changes, not when styles or DOM hierarchy change
- Avoid dynamic IDs like `data-testid="btn-${randomId}"` — use stable entity identifiers
- One `data-testid` per element — don't reuse the same value on multiple elements (Playwright will throw a strict-mode violation)
- For lists, include the row's unique identifier so individual rows can be selected

**Code review enforcement:** PRs that add interactive elements WITHOUT `data-testid` selectors should be rejected. The testing agent will flag missing selectors automatically when it sees a component without coverage.
