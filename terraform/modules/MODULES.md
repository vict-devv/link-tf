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

## `eks`

Provisions an EKS cluster with a managed node group, standard add-ons, and an OIDC provider for IAM Roles for Service Accounts (IRSA).

**Resources created:**
- EKS cluster with public + private API endpoint access
- IAM role for the cluster (`AmazonEKSClusterPolicy`)
- Managed node group (`<cluster_name>-main`)
- IAM role for nodes (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`)
- Cluster add-ons: `coredns`, `kube-proxy`, `vpc-cni`, `aws-ebs-csi-driver`
- IAM OIDC provider (for IRSA)

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
| `tags`                | `map(string)`  | `{}`           | Tags applied to all resources            |

**Outputs:**

| Name                    | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `cluster_endpoint`      | EKS API server endpoint                          |
| `cluster_ca_certificate`| Base64-encoded cluster CA certificate (sensitive)|
| `cluster_name`          | EKS cluster name                                 |
| `oidc_issuer_url`       | OIDC issuer URL                                  |
| `oidc_issuer_arn`       | ARN of the OIDC provider                         |
