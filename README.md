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
│   │   └── version.tf
│   └── prod/             # Production environment
│       ├── backend.tf
│       ├── main.tf
│       └── version.tf
└── modules/
    └── vpc/              # VPC module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `~> 1.10`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate credentials
- Access to the `linkr-tf-state-064160141787` S3 bucket (ca-central-1)

## Environments

| Environment | State Key                    | Region       | NAT Gateways       |
| ----------- | ---------------------------- | ------------ | ------------------ |
| `dev`       | `env/dev/terraform.tfstate`  | ca-central-1 | 1 (cost saving)    |
| `prod`      | `env/prod/terraform.tfstate` | ca-central-1 | 1 per AZ (HA)      |

## Remote State

State is stored in S3 with encryption and native S3 locking enabled (`use_lockfile = true`). No DynamoDB table is required.

**S3 Bucket:** `linkr-tf-state-064160141787`  
**Region:** `ca-central-1`

## Modules

### `vpc`

Provisions a production-grade VPC with public and private subnets across all Availability Zones. Subnets are tagged for EKS discovery so the AWS Load Balancer Controller can find them automatically.

**Resources created:**
- VPC
- Internet Gateway
- Public subnets (one per AZ) — tagged `kubernetes.io/role/elb` for internet-facing load balancers
- Private subnets (one per AZ) — tagged `kubernetes.io/role/internal-elb` for internal load balancers
- Elastic IPs + NAT Gateways (count controlled by `single_nat_gateway`)
- Route tables and associations (one public RT shared, one private RT per NAT GW)

**Variables:**

| Name                  | Type           | Default                                                    | Description                              |
| --------------------- | -------------- | ---------------------------------------------------------- | ---------------------------------------- |
| `name`                | `string`       | —                                                          | Name prefix for all resources            |
| `cidr`                | `string`       | `"10.0.0.0/16"`                                           | VPC CIDR block                           |
| `azs`                 | `list(string)` | `["ca-central-1a", "ca-central-1b", "ca-central-1d"]`    | Availability Zones                       |
| `public_subnets_cidr` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`         | CIDR blocks for public subnets           |
| `private_subnets_cidr`| `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]`      | CIDR blocks for private subnets          |
| `eks_cluster_name`    | `string`       | `""`                                                       | EKS cluster name for subnet tagging      |
| `single_nat_gateway`  | `bool`         | `false`                                                    | Use one shared NAT GW instead of one per AZ |
| `tags`                | `map(string)`  | `{}`                                                       | Additional tags applied to all resources |

**Outputs:**

| Name               | Description                  |
| ------------------ | ---------------------------- |
| `vpc_id`           | ID of the VPC                |
| `vpc_cidr`         | CIDR block of the VPC        |
| `public_subnet_id` | List of public subnet IDs    |
| `private_subnet_id`| List of private subnet IDs   |
| `nat_gateways_id`  | List of NAT Gateway IDs      |

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
