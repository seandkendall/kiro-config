---
inclusion: auto
name: error-handling
description: Error handling patterns for Lambda, React, API Gateway. Use when implementing try/catch, error responses, error boundaries, or exception handling.
---

# Error Handling Standards

## Lambda Functions

- Return structured error responses with error code, message, and requestId
- Use custom exception classes, never raise generic `Exception`

```python
class ValidationError(Exception):
    def __init__(self, message: str, field: str | None = None):
        self.message = message
        self.field = field

def lambda_handler(event, context):
    try:
        # business logic
        pass
    except ValidationError as e:
        return {"statusCode": 400, "body": json.dumps({"error": "VALIDATION_ERROR", "message": e.message, "requestId": context.aws_request_id})}
    except Exception:
        logger.exception("Unexpected error")
        return {"statusCode": 500, "body": json.dumps({"error": "INTERNAL_ERROR", "message": "An unexpected error occurred", "requestId": context.aws_request_id})}
```

## React Components

- Use error boundaries for graceful failure handling
- Every page-level component MUST have an error boundary
- Show user-friendly error messages, never raw stack traces

```tsx
<ErrorBoundary fallback={<ErrorPage />}>
  <Dashboard />
</ErrorBoundary>
```

## API Gateway

- Configure error mapping for consistent JSON error responses
- Never expose internal error details to clients
- Always include `requestId` for traceability
