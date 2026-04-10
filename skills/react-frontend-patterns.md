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
  const { data, isLoading, error } = useQuery({ queryKey: ['dashboard', userId], queryFn: fetchDashboard });

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
  amount: z.number().positive("Must be greater than 0"),
  description: z.string().min(1, "Required"),
});

function TransactionForm() {
  const { register, handleSubmit, formState: { errors } } = useForm({ resolver: zodResolver(schema) });
  return (
    <form onSubmit={handleSubmit(onSubmit)} data-cy="transaction-form">
      <label htmlFor="amount">Amount</label>
      <input id="amount" type="number" aria-invalid={!!errors.amount} aria-describedby="amount-error" {...register("amount", { valueAsNumber: true })} />
      {errors.amount && <p id="amount-error" role="alert">{errors.amount.message}</p>}
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

## data-cy Selectors (for Cypress)
- Every interactive element needs `data-cy`
- Pattern: `data-cy="entity-action"` (e.g., `data-cy="invoice-submit"`)
