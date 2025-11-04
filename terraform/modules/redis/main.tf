# Random password for Redis auth token
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Secrets Manager secret to store Redis auth token
resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "collectorset/redisAuthToken/production"
  description = "Redis AUTH token for collectorset prod environment"
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
  name       = "ecs-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "ecs-redis-subnet-group"
  }
}

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "ecs-redis-sg"
  description = "Allow ECS tasks to connect to Redis"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow ECS to Redis"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    security_groups  = [var.ecs_security_group_id] # ECS SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-redis-sg"
  }
}

# Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "collectorset-redis-prod"
  description = "Redis replication group for collectorset prod"
  node_type                     = "cache.t3.micro"
  num_cache_clusters         = 1
  automatic_failover_enabled    = false
  transit_encryption_enabled    = true
  at_rest_encryption_enabled    = true
  auth_token                    = random_password.redis_auth_token.result
  port                          = 6379
  security_group_ids            = [aws_security_group.redis_sg.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
}