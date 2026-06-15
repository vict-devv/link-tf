locals {
  prod-name = "linkr-prod"

  prod-tags = {
    Environment = "prod"
    Project     = "linkr"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.prod-name
  eks_cluster_name   = local.prod-name
  single_nat_gateway = false # one NAT GW per AZ for prod

  tags = local.prod-tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.prod-name
  cluster_version    = "1.35"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_id

  node_instance_type = "t3.medium"
  node_min_size      = 1
  node_max_size      = 3
  node_desired_size  = 2

  tags = local.prod-tags
}
