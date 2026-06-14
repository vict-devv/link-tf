module "vpc" {
  source = "../../modules/vpc"

  name               = "linkr-prod"
  eks_cluster_name   = "linkr-prod"
  single_nat_gateway = false # one NAT GW per AZ for prod

  tags = {
    Environment = "prod"
    Project     = "linkr"
  }
}
