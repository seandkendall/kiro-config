---
inclusion: auto
name: aws-architecture-diagram
description: 'Generate validated AWS architecture diagrams as draw.io XML using official AWS4 icon libraries. Triggers when user wants to create, generate, or design AWS architecture diagrams, cloud infrastructure diagrams, or system design visuals. Supports codebase analysis and brainstorming modes.'
---

# AWS Architecture Diagram Generator

Generate draw.io XML files with official AWS4 icons matching the style of AWS Reference Architecture diagrams.

## When to Use This Skill vs. aws-diagram-png

- Use **this skill** (`aws-architecture-diagram`) when the user wants **editable draw.io XML** they can refine in [app.diagrams.net](https://app.diagrams.net) before exporting
- Use **`aws-diagram-png`** (the awsdac-based skill) when the user wants a **PNG image directly** for slides, docs, or PRs

The two skills use different AWS icon libraries:

| Skill                             | Icon namespace                                 | Output        |
| --------------------------------- | ---------------------------------------------- | ------------- |
| `aws-architecture-diagram` (this) | `mxgraph.aws4.*` (draw.io's bundled AWS4 set)  | `.drawio` XML |
| `aws-diagram-png`                 | awsdac's `definition-for-aws-icons-light.yaml` | `.png` image  |

Resource type names differ between the two — this skill uses draw.io's `resIcon=mxgraph.aws4.<service>`, while `aws-diagram-png` uses CloudFormation-style `AWS::<Service>::<Resource>` with awsdac-specific fallback rules. Don't mix the two.

## Modes

### Mode A — Codebase Analysis

If user says "analyze", "scan", "from code", or references their existing project:

1. Scan for infrastructure files: CloudFormation, CDK (`cdk.json`), Terraform (`resource "aws_*"`)
2. Extract services, relationships, VPC structure, and data flow
3. For non-AWS technologies (Docker, databases, ML frameworks), map to general icons
4. Confirm discovered architecture with user before generating

### Mode B — Brainstorming

If user describes an architecture or says "brainstorm"/"design"/"from scratch":

1. Ask 3-5 focused questions (purpose, services, scale, security, traffic pattern)
2. Propose the architecture with service recommendations and data flow
3. Iterate if needed, then generate

## Style Rules

- **Font**: ALL text MUST use `fontFamily=Helvetica;`
- **Icon size**: 48x48 inside 120x120 containers with category tint color
- **Spacing**: 180px horizontal, 120px vertical between service group containers
- **Dark mode**: ALL structural elements use `light-dark()` fills with `fillStyle=auto;`
- **Region groups**: Use `container=0` (decoration-only)
- **Group fontColor**: MUST match the group's `strokeColor` (VPC: `#8C4FFF`, Public subnet: `#248814`, Private subnet: `#147EBA`, Region: `#00A4A6`)
- **Step badges**: Teal `#007CBD` 28x28 badges near arrow sources
- **Legend**: Right sidebar for 7+ services (unless user opts out)
- **Sketch mode**: OFF by default, only when user explicitly requests

## XML Structure

```xml
<mxfile>
  <diagram name="..." id="...">
    <mxGraphModel dx="..." dy="..." grid="0" ...>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <!-- diagram elements -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

- Use `mxgraph.aws4.*` namespace with `resourceIcon;resIcon=` for service icons
- Use descriptive cell IDs: `vpc-1`, `lambda-orders`, `s3-assets`
- Edges connect to service icons, not containers
- NEVER use compressed/base64 diagram content
- NEVER use double hyphens (`--`) inside XML comments

## Diagram Types

- **Serverless**: API Gateway, Lambda, DynamoDB, S3, Step Functions, EventBridge
- **VPC/Network**: VPC, subnets, security groups, NAT gateways, load balancers
- **Container**: ECS/EKS clusters, ECR, Fargate, load balancing
- **Multi-Region**: Multiple regions with replication, Route 53, Global Accelerator
- **Data Flow/Analytics**: Kinesis, S3, Glue, Athena, Redshift, QuickSight
- **Hybrid**: On-premises + AWS with Direct Connect, VPN, Transit Gateway

## Output

1. Create `docs/` directory if needed
2. Save diagram to `./docs/<descriptive-name>.drawio`
3. Present: file path, diagram type, services included, validation status
4. Only include services the user mentions or that are core to the data flow — do NOT add cross-cutting concerns (IAM, CloudWatch, CloudTrail, KMS) unless asked

## Prerequisites

- `defusedxml>=0.7.1` for XML validation: `pip3 install defusedxml`
- [draw.io desktop](https://www.drawio.com/) (optional, for PNG/SVG/PDF export)
