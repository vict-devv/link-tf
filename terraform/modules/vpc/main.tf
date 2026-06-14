locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.azs)

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "vpc"
  })
}

# VPC ----------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true # required for EKS and RDS dns resolution
  enable_dns_hostnames = true # required for EKS node registration

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
  })
}

# IGW ----------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id


  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets -----------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${var.azs[count.index]}"
    Tier = "public"
    # EKS tags
    # for internet-facing ALBs/NLBs. Only applied if eks_cluster_name is set
    "kubernetes.io/role/elb"                        = var.eks_cluster_name != "" ? "1" : null
    "kubernetes.io/cluster/${var.eks_cluster_name}" = var.eks_cluster_name != "" ? "shared" : null
  })
}

# Private Subnets ----------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${var.azs[count.index]}"
    Tier = "private"
    # EKS tags
    # for internal ALBs/NLBs. Critical for services not exposed to internet
    "kubernetes.io/role/internal-elb"               = var.eks_cluster_name != "" ? "1" : null
    "kubernetes.io/cluster/${var.eks_cluster_name}" = var.eks_cluster_name != "" ? "shared" : null
  })
}

# NAT Gateways ------------------------------------------------------
resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-eip-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}


# Route Table --------------------------------------------------------
# One single public RT shared to all public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private RT per AZ or one shared when single NAT
resource "aws_route_table" "private" {
  count  = local.nat_gateway_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[
    var.single_nat_gateway ? 0 : count.index
  ].id
}
