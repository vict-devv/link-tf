# Modules

Reusable Terraform modules shared across all environments.

---

## `vpc`

Provisions a production-grade VPC with public and private subnets across all Availability Zones. Subnets are tagged for EKS discovery so the AWS Load Balancer Controller can find them automatically.

**Resources created:**
- VPC
- Internet Gateway
- Public subnets (one per AZ) — tagged `kubernetes.io/role/elb` for internet-facing load balancers
- Private subnets (one per AZ) — tagged `kubernetes.io/role/internal-elb` for internal load balancers
- Elastic IPs + NAT Gateways (count controlled by `single_nat_gateway`)
- Route tables and associations (one public RT shared, one private RT per NAT GW)

**Variables:**

| Name                   | Type           | Default                                                 | Description                                   |
| ---------------------- | -------------- | ------------------------------------------------------- | --------------------------------------------- |
| `name`                 | `string`       | —                                                       | Name prefix for all resources                 |
| `cidr`                 | `string`       | `"10.0.0.0/16"`                                        | VPC CIDR block                                |
| `azs`                  | `list(string)` | `["ca-central-1a", "ca-central-1b", "ca-central-1d"]` | Availability Zones                            |
| `public_subnets_cidr`  | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`      | CIDR blocks for public subnets                |
| `private_subnets_cidr` | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]`   | CIDR blocks for private subnets               |
| `eks_cluster_name`     | `string`       | `""`                                                    | EKS cluster name for subnet tagging           |
| `single_nat_gateway`   | `bool`         | `false`                                                 | Use one shared NAT GW instead of one per AZ   |
| `tags`                 | `map(string)`  | `{}`                                                    | Additional tags applied to all resources      |

**Outputs:**

| Name                | Description                |
| ------------------- | -------------------------- |
| `vpc_id`            | ID of the VPC              |
| `vpc_cidr`          | CIDR block of the VPC      |
| `public_subnet_id`  | List of public subnet IDs  |
| `private_subnet_id` | List of private subnet IDs |
| `nat_gateways_id`   | List of NAT Gateway IDs    |

---

## `rds`

Provisions a PostgreSQL 16 RDS instance in private subnets, accessible only from EKS nodes. Credentials are generated randomly and stored in AWS Secrets Manager.

**Resources created:**
- Security group (port 5432 ingress from EKS node SG only)
- DB parameter group (`postgres16` family, connection logging enabled)
- DB subnet group (private subnets)
- RDS instance (`postgres` engine, gp3, encrypted at rest)
- Secrets Manager secret (`linkr/<env>/postgres/credentials`) with host, port, username, password, and dbname

**Variables:**

| Name                 | Type           | Default   | Description                               |
| -------------------- | -------------- | --------- | ----------------------------------------- |
| `env`                | `string`       | —         | Environment name (`dev`, `prod`)          |
| `vpc_id`             | `string`       | —         | VPC ID                                    |
| `private_subnet_ids` | `list(string)` | —         | Private subnet IDs for the DB subnet group|
| `eks_node_sg_id`     | `string`       | —         | EKS node security group ID                |
| `instance_class`     | `string`       | —         | RDS instance class (e.g. `db.t3.micro`)   |
| `multi_az`           | `bool`         | `false`   | Enable Multi-AZ standby                   |
| `db_name`            | `string`       | `"linkr"` | Initial database name                     |
| `tags`               | `map(string)`  | `{}`      | Tags applied to all resources             |

**Outputs:**

| Name                | Description                                       |
| ------------------- | ------------------------------------------------- |
| `security_group_id` | RDS security group ID                             |
| `secret_arn`        | Secrets Manager ARN for DB credentials            |
| `endpoint`          | RDS endpoint `host:port` (sensitive)              |

---

## `elasticache`

Provisions a Redis 7.1 ElastiCache cluster in private subnets, accessible only from EKS nodes. Connection details are stored in AWS Secrets Manager.

**Resources created:**
- Security group (port 6379 ingress from EKS node SG only)
- ElastiCache subnet group (private subnets)
- ElastiCache cluster (`redis` engine, 7.1)
- Secrets Manager secret (`linkr/<env>/redis/url`) with host and port

**Variables:**

| Name                 | Type           | Default            | Description                                    |
| -------------------- | -------------- | ------------------ | ---------------------------------------------- |
| `env`                | `string`       | —                  | Environment name (`dev`, `prod`)               |
| `vpc_id`             | `string`       | —                  | VPC ID                                         |
| `private_subnet_ids` | `list(string)` | —                  | Private subnet IDs for the subnet group        |
| `eks_node_sg_id`     | `string`       | —                  | EKS node security group ID                     |
| `node_type`          | `string`       | `"cache.t3.micro"` | ElastiCache node type                          |
| `num_cache_nodes`    | `number`       | `1`                | Number of cache nodes                          |
| `tags`               | `map(string)`  | `{}`               | Tags applied to all resources                  |

**Outputs:**

| Name                | Description                                    |
| ------------------- | ---------------------------------------------- |
| `security_group_id` | ElastiCache security group ID                  |
| `secret_arn`        | Secrets Manager ARN for Redis connection       |
| `endpoint`          | Redis endpoint `host:port`                     |

---

## `eks`

Provisions an EKS cluster with a managed node group, standard add-ons, and an OIDC provider for IAM Roles for Service Accounts (IRSA).

**Resources created:**
- EKS cluster with public + private API endpoint access
- IAM role for the cluster (`AmazonEKSClusterPolicy`)
- Managed node group (`<cluster_name>-main`)
- IAM role for nodes (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`)
- Cluster add-ons: `coredns`, `kube-proxy`, `vpc-cni`, `aws-ebs-csi-driver`
- IAM OIDC provider (for IRSA)
- IRSA role for the EBS CSI driver (`AmazonEBSCSIDriverPolicy`)
- IRSA role for External Secrets Operator (read access to `linkr/<env>/*` secrets in Secrets Manager)

**Variables:**

| Name                  | Type           | Default        | Description                              |
| --------------------- | -------------- | -------------- | ---------------------------------------- |
| `cluster_name`        | `string`       | —              | EKS cluster name                         |
| `cluster_version`     | `string`       | `"1.35"`       | Kubernetes version                       |
| `vpc_id`              | `string`       | —              | VPC ID                                   |
| `private_subnet_ids`  | `list(string)` | —              | Private subnet IDs for nodes             |
| `node_instance_type`  | `string`       | `"t3.medium"`  | EC2 instance type for managed node group |
| `node_min_size`       | `number`       | `1`            | Minimum number of nodes                  |
| `node_max_size`       | `number`       | `3`            | Maximum number of nodes                  |
| `node_desired_size`   | `number`       | `2`            | Desired number of nodes                  |
| `environment`         | `string`       | `"prod"`       | Deployment environment (`dev`, `prod`) — scopes ESO Secrets Manager access |
| `tags`                | `map(string)`  | `{}`           | Tags applied to all resources            |

**Outputs:**

| Name                    | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `cluster_endpoint`      | EKS API server endpoint                          |
| `cluster_ca_certificate`| Base64-encoded cluster CA certificate (sensitive)|
| `cluster_name`          | EKS cluster name                                 |
| `oidc_issuer_url`       | OIDC issuer URL                                  |
| `oidc_issuer_arn`       | ARN of the OIDC provider                         |
| `node_security_group_id`| Security group ID attached to EKS nodes          |

---

## `ecr`

Provisions an ECR repository with image scanning on push and a lifecycle policy to cap stored image count.

**Resources created:**
- ECR repository (scanning enabled on push, configurable tag mutability)
- ECR lifecycle policy (expires images beyond the configured retention count)

**Variables:**

| Name                   | Type          | Default      | Description                                                          |
| ---------------------- | ------------- | ------------ | -------------------------------------------------------------------- |
| `name`                 | `string`      | —            | ECR repository name                                                  |
| `image_tag_mutability` | `string`      | `"MUTABLE"`  | Tag mutability setting (`MUTABLE` or `IMMUTABLE`)                   |
| `keep_image_count`     | `number`      | `10`         | Number of most-recent images to retain in the lifecycle policy       |
| `tags`                 | `map(string)` | `{}`         | Tags applied to the repository                                       |

**Outputs:**

| Name               | Description                  |
| ------------------ | ---------------------------- |
| `repository_url`   | Full ECR repository URL      |
| `repository_arn`   | ARN of the ECR repository    |
