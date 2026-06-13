# link-tf

Terraform infrastructure for the [Linkr - URL Shortener Platform](https://github.com/vict-devv/linkr).

## Overview

This repository manages all AWS infrastructure for Linkr using Terraform. It follows a per-environment layout with a shared modules directory for reusable components.

## Repository Structure

```
terraform/
├── envs/
│   ├── dev/          # Development environment
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── version.tf
│   └── prod/         # Production environment
│       ├── backend.tf
│       ├── main.tf
│       └── version.tf
└── modules/          # Shared reusable modules (in progress)
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `~> 1.10`
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate credentials
- Access to the `linkr-tf-state-064160141787` S3 bucket (ca-central-1)

## Environments

| Environment | State Key                    | Region       |
| ----------- | ---------------------------- | ------------ |
| `dev`       | `env/dev/terraform.tfstate`  | ca-central-1 |
| `prod`      | `env/prod/terraform.tfstate` | ca-central-1 |

## Remote State

State is stored in S3 with encryption and native S3 locking enabled (`use_lockfile = true`). No DynamoDB table is required.

**S3 Bucket:** `linkr-tf-state-064160141787`
**Region:** `ca-central-1`

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
