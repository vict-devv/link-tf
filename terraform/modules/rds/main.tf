# Security Group -----------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "linkr-${var.env}-rds-sg"
  description = "Postgres access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
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
    Name = "linkr-${var.env}-rds-sg"
  })
}

# Parameter and Subnet Groups ----------------------------------------
resource "aws_db_parameter_group" "postgres16" {
  name        = "linkr-${var.env}-pg16"
  description = "Linkr Postgres 16 parameters"
  family      = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = var.tags
}

resource "aws_db_subnet_group" "this" {
  name        = "linkr-${var.env}-rds-subnet-group"
  description = "Private subnets for Linkr RDS"
  subnet_ids  = var.private_subnet_ids

  tags = var.tags
}

# RDS Instance -------------------------------------------------------
resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "postgres" {
  identifier        = "linkr-${var.env}-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = "linkr"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres16.name

  multi_az            = var.multi_az
  publicly_accessible = false

  skip_final_snapshot = var.env == "dev" ? true : false
  deletion_protection = var.env == "prod" ? true : false

  tags = merge(var.tags, {
    Name = "linkr-${var.env}-postgres"
  })
}

# Secrets Manager ----------------------------------------------------
resource "aws_secretsmanager_secret" "db" {
  name        = "linkr/${var.env}/postgres/credentials"
  description = "Linkr Postgres credentials (${var.env})"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  # The Go services call once and unmarshall to get all parameters
  secret_string = jsonencode({
    username = "${aws_db_instance.postgres.username}"
    password = "${random_password.db.result}"
    host     = "${aws_db_instance.postgres.address}"
    port     = "${aws_db_instance.postgres.port}"
    dbname   = "${aws_db_instance.postgres.db_name}"
  })
}
