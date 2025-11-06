# Cognito Outputs
output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = var.enable_cognito ? module.cognito[0].user_pool_id : null
}

output "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = var.enable_cognito ? module.cognito[0].user_pool_arn : null
}

output "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = var.enable_cognito ? module.cognito[0].client_id : null
}

output "cognito_client_secret" {
  description = "The client secret of the Cognito User Pool Client (only if generate_client_secret is true)"
  value       = var.enable_cognito ? module.cognito[0].client_secret : null
  sensitive   = true
}

# Redis Outputs
output "redis_endpoint" {
  description = "Primary endpoint address for the Redis cluster"
  value       = var.enable_redis ? module.redis[0].redis_endpoint : null
}

output "redis_reader_endpoint" {
  description = "Reader endpoint address for the Redis cluster"
  value       = var.enable_redis ? module.redis[0].redis_reader_endpoint : null
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the Redis auth token"
  value       = var.enable_redis ? module.redis[0].redis_secret_arn : null
}

output "redis_security_group_id" {
  description = "Security Group ID for Redis"
  value       = var.enable_redis ? module.redis[0].redis_security_group_id : null
}

output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = var.enable_redis ? module.redis[0].replication_group_id : null
}

