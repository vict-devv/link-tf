locals {
  environment = "prod"
  prod-name   = "linkr-prod"

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

  environment = local.environment

  tags = local.prod-tags
}

module "rds" {
  source = "../../modules/rds"

  env                = local.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_id
  eks_node_sg_id     = module.eks.node_security_group_id
  instance_class     = "db.t3.small"
  multi_az           = true

  tags = local.prod-tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  env                = local.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_id
  eks_node_sg_id     = module.eks.node_security_group_id
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1

  tags = local.prod-tags
}
