# Random password for Redis auth token
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Secrets Manager secret to store Redis auth token
resource "aws_secretsmanager_secret" "redis_auth" {
  name        = var.secret_name
  description = var.secret_description
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_auth_version" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    username = "default"
    password = random_password.redis_auth_token.result
  })
}

# Elasticache subnet group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = var.subnet_group_name
  subnet_ids = var.private_subnets
  tags       = var.tags
}

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = var.security_group_name })

  ingress {
    description     = "Allow ECS to Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.replication_group_id
  description                = var.description
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.automatic_failover_enabled
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  port                       = 6379
  engine_version             = var.redis_engine_version
  security_group_ids         = [aws_security_group.redis_sg.id]
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  tags                       = var.tags
}