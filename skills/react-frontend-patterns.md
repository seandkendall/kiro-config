---
name: react-frontend-patterns
description: React 18+, TypeScript, Tailwind CSS, shadcn/ui component patterns, accessibility, forms, state management. Use when building or reviewing React components, pages, or frontend architecture.
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
    <main data-cy="dashboard-page">
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
    <form onSubmit={handleSubmit(onSubmit)} data-cy="transaction-form">
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
- Use shadcn/ui Dialog instead of browser `alert()`/`confirm()`

## Responsive Breakpoints

- Mobile: 375px (default, mobile-first)
- Tablet: `md:` (768px)
- Desktop: `lg:` (1280px)
- Touch targets: minimum 44x44px on mobile

## data-cy Selectors (MANDATORY — for Cypress)

`data-cy` attributes are **REQUIRED** on every interactive element. Cypress tests are non-negotiable in this codebase, and CSS/class selectors break tests when styles change.

**Required on:**

- Every `<button>` / `<a>` (clickable)
- Every `<input>` / `<select>` / `<textarea>` (user input)
- Every `<form>` (submission target)
- Every page-level container (test entry point)
- Every error/success message (assertion target)
- Every modal / dialog (visibility check)
- Every loading indicator (race-condition guard)

**Naming pattern:** `data-cy="<entity>-<action>"` or `data-cy="<entity>-<role>"`

| Element        | Pattern                  | Example                          |
| -------------- | ------------------------ | -------------------------------- |
| Submit button  | `<entity>-submit`        | `data-cy="invoice-submit"`       |
| Cancel button  | `<entity>-cancel`        | `data-cy="invoice-cancel"`       |
| Form input     | `<entity>-<field>-input` | `data-cy="invoice-amount-input"` |
| Error message  | `<entity>-error`         | `data-cy="invoice-error"`        |
| Page container | `<page>-page`            | `data-cy="dashboard-page"`       |
| List item      | `<entity>-row-<id>`      | `data-cy="invoice-row-123"`      |
| Modal          | `<entity>-modal`         | `data-cy="delete-confirm-modal"` |

**Rules:**

- Never use class selectors, IDs, or tag selectors in Cypress — `cy.get('[data-cy=...]')` only
- Keep selectors **stable** — only change them when the element's purpose changes, not when styles or DOM hierarchy change
- Avoid dynamic IDs like `data-cy="btn-${randomId}"` — use stable entity identifiers
- One `data-cy` per element — don't reuse the same value on multiple elements (Cypress will be ambiguous)
- For lists, include the row's unique identifier so individual rows can be selected

**Code review enforcement:** PRs that add interactive elements WITHOUT `data-cy` selectors should be rejected. The Cypress agent will flag missing selectors automatically when it sees a component without coverage.
