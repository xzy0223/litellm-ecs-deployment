# RDS PostgreSQL for LiteLLM

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "litellm-rds-sg"
  description = "Security group for LiteLLM RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "litellm-rds-sg"
  }
}

# DB subnet group (includes both public and private subnets during migration)
resource "aws_db_subnet_group" "litellm_db_subnet_group" {
  name       = "litellm-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id,
    aws_subnet.private_az3.id
  ]

  tags = {
    Name = "LiteLLM DB subnet group"
  }
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "litellm-db-password"
  description = "LiteLLM RDS PostgreSQL password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "litellm_admin"
    password = random_password.db_password.result
  })
}

# RDS PostgreSQL instance
resource "aws_db_instance" "litellm_db" {
  identifier             = "litellm-postgres-db"
  engine                 = "postgres"
  engine_version         = "16.11"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = "litellm"
  username = "litellm_admin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.litellm_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "litellm-postgres-db"
  }
}

# Output the connection URL
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.litellm_db.endpoint
  sensitive   = false
}

output "rds_connection_url" {
  description = "RDS PostgreSQL connection URL"
  value       = "postgresql://${aws_db_instance.litellm_db.username}:${random_password.db_password.result}@${aws_db_instance.litellm_db.endpoint}/${aws_db_instance.litellm_db.db_name}"
  sensitive   = true
}
