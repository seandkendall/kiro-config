---
inclusion: auto
name: api-standards
description: REST and GraphQL API design patterns, error response formats, endpoint naming, pagination, authentication flows. Use when creating or modifying API endpoints, resolvers, or routes.
---

# API Standards

## REST Conventions

- Plural nouns for resources: `/invoices`, `/transactions`, `/users`
- Kebab-case for multi-word paths: `/tax-returns`, `/bank-accounts`
- Nest related resources: `/invoices/{id}/line-items`
- Use query params for filtering: `/transactions?status=pending&from=2025-01-01`
- Version via path prefix when needed: `/v1/invoices`

## API Routing (MANDATORY)

- **ALL backend APIs MUST be served through the same root domain as the web app**, under a `/api` or `/rest` path prefix (e.g., `https://myapp.example.com/api/invoices`)
- Use CloudFront with path-based routing: `/api/*` → API Gateway origin, `/*` → S3/frontend origin
- This eliminates cross-origin requests entirely — CORS policy becomes `same-origin` (simplest, most secure)
- Never host APIs on a separate subdomain (e.g., `api.myapp.example.com`) unless there is a specific technical requirement

## HTTP Methods

- GET: Read (never mutate state)
- POST: Create new resource
- PUT: Full replace
- PATCH: Partial update
- DELETE: Remove resource

## Response Format

```json
{
  "data": {},
  "meta": { "requestId": "abc-123", "timestamp": "2025-01-01T00:00:00Z" }
}
```

## Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invoice amount must be positive",
    "details": [{ "field": "amount", "issue": "Must be greater than 0" }]
  },
  "meta": { "requestId": "abc-123" }
}
```

## Status Codes

- 200: Success
- 201: Created
- 400: Validation error (client fault)
- 401: Unauthenticated
- 403: Unauthorized (insufficient permissions)
- 404: Resource not found
- 409: Conflict (duplicate, state conflict)
- 429: Rate limited
- 500: Internal server error

## Pagination

- Cursor-based for DynamoDB: `?cursor=<lastEvaluatedKey>&limit=25`
- Return `nextCursor` in response, `null` when no more pages
- Default limit: 25, max limit: 100

## GraphQL (AppSync)

- Use input types for mutations: `input CreateInvoiceInput { ... }`
- Return the mutated object from mutations
- Use connections pattern for paginated lists: `{ items: [], nextToken: string }`
- Implement field-level authorization with `@auth` directives
- Use AppSync subscriptions for real-time updates — subscribe to mutations with `@aws_subscribe` directive

## Authentication

- All endpoints require Bearer token unless explicitly public
- Validate JWT at API Gateway (Cognito authorizer) AND Lambda (defense in depth)
- Include `requestId` in all responses for traceability

## CORS

- Explicitly list allowed origins — never use `*` in production
- Allow only required HTTP methods and headers
- Set `Access-Control-Max-Age` to 3600 for preflight caching

## Request Validation

- All API endpoints MUST validate request bodies at the gateway level
- REST: Use API Gateway request models to reject malformed requests before Lambda
- GraphQL: Use AppSync input type validation and VTL/JS resolver input checks
- Defense in depth: validate again in Lambda with pydantic (Python) or zod (TypeScript)

## Python ↔ TypeScript Contract (MANDATORY)

JSON serialisation turns Python `None` into JSON `null`, not `undefined`. On the TypeScript side, `z.X().optional()` accepts `undefined` but REJECTS `null`. A schema with `z.string().optional()` therefore fails to parse any payload where the Lambda emits `"field": null`, which silently breaks every consumer of that endpoint.

**Rules:**

- For any Python field typed `Optional[X]` (or `X | None`) that is **always present in the JSON response** (e.g., not stripped via `exclude_none`), the matching zod field MUST be `.nullable()`, not `.optional()`.
- Prefer `.nullable()` over `.optional()` by default for any field backed by an `Optional[X]` Python value. Use `.optional()` only when the Python side deliberately omits the key from the dict via `model_dump(exclude_none=True)` or similar.
- When in doubt: `.nullable().optional()` accepts `null`, `undefined`, and present-as-X, so it's the safest choice for fields that might be omitted OR emitted as null.

**Python → TypeScript mapping table:**

| Python type (pydantic)                                     | JSON emitted                | TypeScript (zod)                   |
| ---------------------------------------------------------- | --------------------------- | ---------------------------------- |
| `str`                                                      | `"value"`                   | `z.string()`                       |
| `Optional[str]` + `exclude_none=True`                      | key absent                  | `z.string().optional()`            |
| `Optional[str]` (default, key always present)              | `null` or `"value"`         | `z.string().nullable()`            |
| `Optional[str]` (mixed — sometimes absent, sometimes null) | `null` / absent / `"value"` | `z.string().nullable().optional()` |

**Enforcement:**

- Every `/api/*` Lambda MUST have a contract test that loads the real response fixture and runs it through the matching zod schema — mismatches break the build.
- In dev mode, `apiFetch` logs the first three zod issues to `console.warn` with full JSON paths so schema drift is obvious at first render rather than invisible behind a generic "Could not load" error.
