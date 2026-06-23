# link-tf

Terraform infrastructure for the [Linkr - URL Shortener Platform](https://github.com/vict-devv/linkr).

## Overview

This repository manages all AWS infrastructure for Linkr using Terraform. It follows a per-environment layout with a shared modules directory for reusable components.

## Repository Structure

```
terraform/
├── envs/
│   ├── dev/              # Development environment
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── version.tf
│   └── prod/             # Production environment
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── version.tf
└── modules/
    ├── ecr/              # ECR repository module
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── eks/              # EKS cluster module
    │   ├── iam.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── elasticache/      # ElastiCache (Redis) module
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── rds/              # RDS (PostgreSQL) module
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── vpc/              # VPC module
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `~> 1.10`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate credentials
- Access to the `linkr-tf-state-064160141787` S3 bucket (ca-central-1)

## Environments

| Environment | State Key                    | Region       | NAT Gateways    |
| ----------- | ---------------------------- | ------------ | --------------- |
| `dev`       | `env/dev/terraform.tfstate`  | ca-central-1 | 1 (cost saving) |
| `prod`      | `env/prod/terraform.tfstate` | ca-central-1 | 1 per AZ (HA)   |

## Remote State

State is stored in S3 with encryption and native S3 locking enabled (`use_lockfile = true`). No DynamoDB table is required.

**S3 Bucket:** `linkr-tf-state-064160141787`
**Region:** `ca-central-1`

## Modules

See [terraform/modules/README.md](terraform/modules/MODULES.md) for full documentation on each module.

| Module                                          | Description                                                                                  |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [`vpc`](terraform/modules/vpc/)                 | Production-grade VPC with public/private subnets and NAT Gateways, tagged for EKS discovery  |
| [`eks`](terraform/modules/eks/)                 | EKS cluster with managed node group, standard add-ons, and OIDC provider for IRSA            |
| [`rds`](terraform/modules/rds/)                 | PostgreSQL 16 RDS instance with encrypted storage and credentials stored in Secrets Manager   |
| [`elasticache`](terraform/modules/elasticache/) | Redis 7.1 ElastiCache cluster with connection details stored in Secrets Manager               |
| [`ecr`](terraform/modules/ecr/)                 | ECR repository with image scanning on push and lifecycle policy to cap stored image count     |

## Usage

### Initialize

```bash
cd terraform/envs/<env>
terraform init
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Destroy

```bash
terraform destroy
```

Replace `<env>` with `dev` or `prod`.

## Provider

| Provider        | Version  |
| --------------- | -------- |
| `hashicorp/aws` | `6.50.0` |
