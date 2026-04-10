---
inclusion: auto
name: performance-optimization
description: Lambda cold starts, memory tuning, React code splitting, CloudFront caching, DynamoDB query optimization. Use when discussing performance, latency, cold starts, bundle size, or caching.
---

# Performance Optimization

## Lambda Optimization

**Memory Configuration**:
- Start with 512MB for most functions
- Monitor CloudWatch metrics to optimize
- Higher memory = faster CPU, but higher cost

**Cold Start Reduction**:
- Minimize dependencies in deployment package
- Initialize connections outside handler function
- Use environment variables for configuration
- Keep handler function lightweight

**Code Optimization**:
```python
# ✅ Initialize outside handler
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    # Handler logic here
    pass
```

## React Performance

**Code Splitting**:
```typescript
// Lazy load components
const Dashboard = lazy(() => import('./Dashboard'))

// Use Suspense for loading states
<Suspense fallback={<Loading />}>
  <Dashboard />
</Suspense>
```

**Bundle Optimization**:
- Use Vite's built-in tree shaking
- Analyze bundle size with `npm run build -- --analyze`
- Lazy load routes and heavy components

## CloudFront Caching

**Static Assets**:
- Cache CSS/JS files for 1 year
- Use versioned filenames for cache busting
- Set appropriate cache headers

**API Responses**:
- Cache GET requests when appropriate
- Use cache-control headers
- Consider edge caching for read-heavy APIs

## DynamoDB Performance

**Query Optimization**:
- Use partition keys effectively
- Design GSIs for access patterns
- Avoid scans, prefer queries
- Use pagination for large result sets

**Cost-Effective Patterns**:
- Use on-demand billing for variable workloads
- Monitor read/write capacity metrics
- Implement efficient data modeling

## Monitoring

**Key Metrics to Track**:
- Lambda duration and memory usage
- API Gateway latency and error rates
- CloudFront cache hit ratio
- DynamoDB throttling events

**No Cost Additions**:
- Use CloudWatch free tier metrics
- Leverage AWS Lambda Powertools for observability
- Monitor via AWS Console dashboards
