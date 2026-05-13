---
inclusion: auto
name: aws-diagram-png
description: 'Generate AWS architecture diagrams as PNG images with real AWS icons using the awslabs/diagram-as-code (awsdac) CLI. Triggers when user wants a PNG diagram, architecture image, or visual export of AWS infrastructure. Produces publication-ready diagrams following AWS architecture guidelines.'
---

# AWS Diagram PNG Generator (awsdac)

Generate production-ready PNG diagrams with official AWS architecture icons using the `awsdac` CLI tool. Use this skill when the user wants a **PNG image** (not draw.io XML).

## When to Use This Skill vs. aws-architecture-diagram

- Use **this skill** (`aws-diagram-png`) when the user wants a PNG file directly, a ready-to-share image, or a diagram for a slide/doc
- Use **`aws-architecture-diagram`** when the user wants editable draw.io XML that they can modify later in [app.diagrams.net](https://app.diagrams.net)

## Prerequisites

`awsdac` must be installed on the user's machine:

```bash
# macOS
brew install awsdac

# Go 1.21+
go install github.com/awslabs/diagram-as-code/cmd/awsdac@latest
```

Verify with: `awsdac --version`

## Workflow

### Mode A — Codebase Analysis

If the user says "analyze", "scan", "from code", or references their existing project:

1. Scan for infrastructure files: CloudFormation (`*.yaml`, `*.json`), CDK (`cdk.json`, `app.py`), Terraform (`*.tf`)
2. Extract services, relationships, VPC structure, and data flow
3. Confirm discovered architecture with the user before generating
4. **Shortcut**: If the user has a CloudFormation template, use `awsdac -c template.yaml` to auto-generate the diagram directly (beta feature)

### Mode B — Brainstorming / From Scratch

If the user describes an architecture or says "brainstorm" / "design" / "from scratch":

1. Ask 3-5 focused questions (purpose, services, scale, security, traffic pattern)
2. Propose the architecture with service recommendations and data flow
3. Iterate if needed, then generate

## Generation Steps

1. Write the YAML file (see structure below) to a sensible path — typically `docs/diagrams/<name>.yaml` or `architecture/<name>.yaml`
2. Run: `awsdac <name>.yaml -o <name>.png`
3. Verify the PNG was created: check that output file exists and is non-zero size
4. Tell the user the path to the generated PNG

## YAML Structure

```yaml
Diagram:
  DefinitionFiles:
    - Type: URL
      Url: 'https://raw.githubusercontent.com/awslabs/diagram-as-code/main/definitions/definition-for-aws-icons-light.yaml'

  Resources:
    Canvas:
      Type: AWS::Diagram::Canvas
      Direction: vertical
      Children:
        - AWSCloud
        - User

    AWSCloud:
      Type: AWS::Diagram::Cloud
      Direction: vertical
      Preset: AWSCloudNoLogo
      Align: center
      Children:
        - VPC

    VPC:
      Type: AWS::EC2::VPC
      Direction: vertical
      Children:
        - PublicSubnet
        - ALB
      BorderChildren:
        - Position: S
          Resource: IGW

    PublicSubnet:
      Type: AWS::EC2::Subnet
      Preset: PublicSubnet
      Children:
        - WebServer

    WebServer:
      Type: AWS::EC2::Instance

    ALB:
      Type: AWS::ElasticLoadBalancingV2::LoadBalancer
      Preset: Application Load Balancer

    IGW:
      Type: AWS::EC2::InternetGateway

    User:
      Type: AWS::Diagram::Resource
      Preset: User

  Links:
    - Source: User
      Target: IGW
      TargetArrowHead:
        Type: Open
    - Source: IGW
      Target: ALB
      TargetArrowHead:
        Type: Open
    - Source: ALB
      Target: WebServer
      TargetArrowHead:
        Type: Open
```

## Key YAML Conventions

- **DefinitionFiles**: Always use the official `definition-for-aws-icons-light.yaml` URL (has real AWS icons)
- **Canvas**: Always the root. Set `Direction: vertical` or `horizontal`
- **AWSCloud**: Wraps anything running inside AWS. Use `Preset: AWSCloudNoLogo` for cleaner look
- **VPC / Subnet**: Use `Preset: PublicSubnet` or `Preset: PrivateSubnet` for color coding
- **Resource types**: Use CloudFormation resource types (e.g., `AWS::Lambda::Function`, `AWS::DynamoDB::Table`, `AWS::S3::Bucket`)
- **Links**: Connect resources with arrows. `TargetArrowHead: Type: Open` is standard

## Common Resource Types

> **Note:** Prefer the base service type (e.g., `AWS::CloudFront`) when a specific variant isn't defined in awsdac's icon file. Variants like `AWS::CloudFront::Distribution` fall back to the base icon with a warning. The types below are all verified to render cleanly with zero warnings.

| Service        | Type                                                                                   |
| -------------- | -------------------------------------------------------------------------------------- |
| Lambda         | `AWS::Lambda::Function`                                                                |
| API Gateway    | `AWS::ApiGateway` (REST) / `AWS::ApiGatewayV2::Api` (HTTP)                             |
| DynamoDB       | `AWS::DynamoDB::Table`                                                                 |
| S3             | `AWS::S3::Bucket`                                                                      |
| CloudFront     | `AWS::CloudFront`                                                                      |
| Cognito        | `AWS::Cognito::UserPool`                                                               |
| SQS            | `AWS::SQS::Queue`                                                                      |
| SNS            | `AWS::SNS::Topic`                                                                      |
| Step Functions | `AWS::StepFunctions`                                                                   |
| EventBridge    | `AWS::Events`                                                                          |
| EC2 Instance   | `AWS::EC2::Instance`                                                                   |
| RDS            | `AWS::RDS::DBInstance`                                                                 |
| ECS            | `AWS::ECS::Service`                                                                    |
| ALB            | `AWS::ElasticLoadBalancingV2::LoadBalancer` (with `Preset: Application Load Balancer`) |
| VPC            | `AWS::EC2::VPC`                                                                        |
| Subnet         | `AWS::EC2::Subnet` (with `Preset: PublicSubnet` or `PrivateSubnet`)                    |
| CloudWatch     | `AWS::CloudWatch::Alarm`                                                               |
| X-Ray          | `AWS::XRay`                                                                            |
| Secrets Mgr    | `AWS::SecretsManager::Secret`                                                          |
| User / Client  | `AWS::Diagram::Resource` with `Preset: User`                                           |

See the full list at: https://github.com/awslabs/diagram-as-code/blob/main/doc/resource-types.md

## CLI Options

```bash
# Basic usage - generates output.png by default
awsdac diagram.yaml

# Custom output path
awsdac diagram.yaml -o architecture.png

# Convert CloudFormation template directly (beta)
awsdac -c cloudformation.yaml -o diagram.png

# Generate YAML from CloudFormation for manual editing
awsdac -c cloudformation.yaml -d -o diagram.yaml

# Verbose logging for debugging
awsdac diagram.yaml -v
```

## Best Practices

- **Keep diagrams focused** — one diagram per concern (data flow, security, deployment) beats one giant diagram
- **Add a User resource** at the top or left edge for flows that start with users
- **Group by VPC/Subnet** to clearly show network boundaries
- **Use consistent direction** — `vertical` for top-to-bottom data flow, `horizontal` for step-by-step
- **Save the YAML alongside the PNG** so the diagram can be regenerated or tweaked later

## Troubleshooting

- **"command not found: awsdac"** — Run `brew install awsdac` (macOS) or use `go install`
- **"unknown resource type"** — Check the resource-types.md doc; use the exact CloudFormation-style name
- **Ugly layout** — Reorganize the `Children` lists; resources stack in the order listed. Try switching `Direction` between `vertical` and `horizontal`
- **Text is cut off** — The tool auto-sizes; if specific labels are wrong, use `Title:` field on the resource

## Reference Links

- [awsdac GitHub](https://github.com/awslabs/diagram-as-code)
- [Example YAMLs](https://github.com/awslabs/diagram-as-code/tree/main/examples)
- [Resource Types](https://github.com/awslabs/diagram-as-code/blob/main/doc/resource-types.md)
- [Introduction Guide](https://github.com/awslabs/diagram-as-code/blob/main/doc/introduction.md)
