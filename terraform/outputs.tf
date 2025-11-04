# Cognito Outputs
output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = module.cognito.user_pool_arn
}

output "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = module.cognito.client_id
}

output "cognito_client_secret" {
  description = "The client secret of the Cognito User Pool Client (only if generate_client_secret is true)"
  value       = module.cognito.client_secret
  sensitive   = true
}

# Redis Outputs
output "redis_endpoint" {
  description = "Primary endpoint address for the Redis cluster"
  value       = module.redis.redis_endpoint
}

output "redis_reader_endpoint" {
  description = "Reader endpoint address for the Redis cluster"
  value       = module.redis.redis_reader_endpoint
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the Redis auth token"
  value       = module.redis.redis_secret_arn
}

output "redis_security_group_id" {
  description = "Security Group ID for Redis"
  value       = module.redis.redis_security_group_id
}

output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = module.redis.replication_group_id
}

