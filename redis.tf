# ElastiCache Redis for LiteLLM caching

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "litellm-redis-sg"
  description = "Security group for LiteLLM ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
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
    Name = "litellm-redis-sg"
  }
}

# ElastiCache subnet group (includes both public and private subnets during migration)
resource "aws_elasticache_subnet_group" "litellm_redis_subnet_group" {
  name       = "litellm-redis-subnet-group"
  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id,
    aws_subnet.private_az3.id
  ]

  tags = {
    Name = "LiteLLM Redis subnet group"
  }
}

# ElastiCache Redis cluster
resource "aws_elasticache_cluster" "litellm_redis" {
  cluster_id           = "litellm-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.litellm_redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  snapshot_retention_limit = 5
  snapshot_window         = "03:00-05:00"

  tags = {
    Name = "litellm-redis"
  }
}

# Output the Redis endpoint
output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_cluster.litellm_redis.cache_nodes[0].address
  sensitive   = false
}

output "redis_port" {
  description = "Redis cluster port"
  value       = aws_elasticache_cluster.litellm_redis.port
  sensitive   = false
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${aws_elasticache_cluster.litellm_redis.cache_nodes[0].address}:${aws_elasticache_cluster.litellm_redis.port}"
  sensitive   = false
}
