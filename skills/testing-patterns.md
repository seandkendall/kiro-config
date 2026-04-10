---
name: testing-patterns
description: pytest with moto, Jest/Vitest with React Testing Library, Cypress E2E patterns. Use when writing or reviewing tests, setting up test infrastructure, or debugging test failures.
---

# Testing Patterns

## Python Lambda Test (pytest + moto)

```python
import pytest
from moto import mock_aws
import boto3, os

@pytest.fixture
def dynamodb_table():
    with mock_aws():
        os.environ["TABLE_NAME"] = "test-table"
        client = boto3.client("dynamodb", region_name="us-east-1")
        client.create_table(
            TableName="test-table",
            KeySchema=[{"AttributeName": "PK", "KeyType": "HASH"}, {"AttributeName": "SK", "KeyType": "RANGE"}],
            AttributeDefinitions=[{"AttributeName": "PK", "AttributeType": "S"}, {"AttributeName": "SK", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield client

def test_handler_success(dynamodb_table):
    from my_function import lambda_handler
    result = lambda_handler({"body": '{"name": "test"}'}, MockContext())
    assert result["statusCode"] == 200

def test_handler_validation_error(dynamodb_table):
    from my_function import lambda_handler
    result = lambda_handler({"body": '{}'}, MockContext())
    assert result["statusCode"] == 400
```

## React Component Test (Vitest + RTL)

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

test('submits form with valid data', async () => {
  const onSubmit = vi.fn();
  render(<InvoiceForm onSubmit={onSubmit} />);
  await userEvent.type(screen.getByLabelText('Amount'), '100');
  await userEvent.click(screen.getByRole('button', { name: 'Submit' }));
  expect(onSubmit).toHaveBeenCalledWith(expect.objectContaining({ amount: 100 }));
});

test('has no accessibility violations', async () => {
  const { container } = render(<InvoiceForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```

## Coverage Commands

- Python: `pytest --cov --cov-report=term-missing --cov-fail-under=90`
- React: `npx vitest --coverage`
- Cypress: `npx cypress run` with `@cypress/code-coverage`
- Target: 100%. Never settle below 90%.

## Cypress Quick Reference

- Selectors: `[data-cy="..."]` only
- Auth: `cy.session()` + `cy.request()`, never UI login
- Waiting: `cy.intercept()` + `cy.wait('@alias')`, never `cy.wait(ms)`
- Structure: `cypress/e2e/*.cy.ts`, `cypress/pages/*.ts`
