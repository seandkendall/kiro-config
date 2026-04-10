---
inclusion: auto
name: troubleshooting
description: CDK deployment errors, Lambda cold starts, API Gateway CORS, Cognito auth failures, React build issues. Use when debugging errors, failures, or unexpected behavior.
---

# Troubleshooting Guide

## CDK Deployment Issues

**GSI Creation Errors**:
- Error: "Cannot perform more than one GSI creation or deletion"
- Solution: Deploy GSI changes one at a time, wait for completion

**Stack Name Conflicts**:
- Error: "Stack already exists"
- Solution: Use unique, project-specific stack names

**cdk-nag Failures**:
- Check security validation rules
- Add suppressions only with proper justification

## Lambda Function Issues

**Cold Start Performance**:
- Check memory allocation (512MB minimum recommended)
- Verify dependencies are optimized
- Review initialization code outside handler

**Permission Errors**:
- Verify IAM roles have required permissions
- Check resource-based policies
- Confirm execution role is attached

## API Gateway Issues

**CORS Errors**:
- Verify CORS configuration in CDK
- Check preflight OPTIONS requests
- Confirm allowed origins and headers

**Authentication Failures**:
- Verify Cognito JWT token format
- Check token expiration
- Confirm authorizer configuration

## React/Frontend Issues

**Build Failures**:
- Run `npm run lint` to check for errors
- Verify all imports are resolved
- Check TypeScript compilation errors

**Deployment Issues**:
- Confirm S3 bucket permissions
- Verify CloudFront distribution settings
- Check build output directory structure

## Cypress E2E Issues

**`cy.session()` not caching**:
- Check `testIsolation` is enabled in cypress.config.ts
- Verify session setup function is deterministic

**`cy.intercept()` not matching**:
- Check route pattern matches the actual request URL
- Verify HTTP method matches (GET vs POST)
- Use `cy.intercept('**/api/**')` for broad matching, then narrow down

**Flaky tests**:
- Replace `cy.wait(ms)` with `cy.wait('@alias')` using intercept aliases
- Use `.should()` assertions which auto-retry
- Add `{ timeout: 10000 }` to slow-loading element queries
