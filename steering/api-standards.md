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
