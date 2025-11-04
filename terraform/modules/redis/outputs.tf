output "redis_endpoint" {
  description = "Primary endpoint address for the Redis cluster"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint address for the Redis cluster"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "redis_security_group_id" {
  description = "Security Group ID for Redis"
  value       = aws_security_group.redis_sg.id
}

output "replication_group_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.redis.id
}