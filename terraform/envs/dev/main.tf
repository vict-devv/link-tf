locals {
  dev-name = "linkr-dev"

  dev-tags = {
    Environment = "dev"
    Project     = "linkr"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.dev-name
  eks_cluster_name   = local.dev-name
  single_nat_gateway = true # a single NAT GW for dev

  tags = local.dev-tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.dev-name
  cluster_version    = "1.35"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_id

  node_instance_type = "t3.medium"
  node_min_size      = 1
  node_max_size      = 3
  node_desired_size  = 2

  tags = local.dev-tags
}
