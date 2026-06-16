# Security Group -----------------------------------------------------
resource "aws_security_group" "redis" {
  name        = "linkr-${var.env}-redis-sg"
  description = "Redis access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "linkr-${var.env}-redis-sg"
  })
}

# Subnet Group -------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  name       = "linkr-${var.env}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# ElastiCache Cluster ------------------------------------------------
resource "aws_elasticache_cluster" "redis" {
  cluster_id      = "linkr-${var.env}-redis"
  engine          = "redis"
  engine_version  = "7.1"
  node_type       = var.node_type
  num_cache_nodes = var.num_cache_nodes
  port            = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  snapshot_retention_limit = var.env == "prod" ? 1 : 0

  tags = merge(var.tags, {
    Name = "linkr-${var.env}-redis"
  })
}

# Secrets Manager ----------------------------------------------------
resource "aws_secretsmanager_secret" "redis" {
  name        = "linkr/${var.env}/redis/url"
  description = "Linkr Redis connection details (${var.env})"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  # The Go services call once and unmarshall to get all parameters
  secret_string = jsonencode({
    host = "${aws_elasticache_cluster.redis.cache_nodes[0].address}"
    port = "${aws_elasticache_cluster.redis.cache_nodes[0].port}"
  })
}
