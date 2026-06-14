module "vpc" {
  source = "../../modules/vpc"

  name               = "linkr-dev"
  eks_cluster_name   = "linkr-dev"
  single_nat_gateway = true # a single NAT GW for dev

  tags = {
    Environment = "dev"
    Project     = "linkr"
  }
}
