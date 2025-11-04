# Cognito User Pool Module
module "cognito" {
  source = "./modules/cognito"

  user_pool_name              = var.user_pool_name
  client_name                 = var.cognito_client_name
  auto_verified_attributes    = var.cognito_auto_verified_attributes
  email_sending_account       = var.cognito_email_sending_account
  verification_email_option   = var.cognito_verification_email_option
  password_minimum_length     = var.cognito_password_minimum_length
  password_require_lowercase  = var.cognito_password_require_lowercase
  password_require_numbers    = var.cognito_password_require_numbers
  password_require_symbols    = var.cognito_password_require_symbols
  password_require_uppercase  = var.cognito_password_require_uppercase
  explicit_auth_flows         = var.cognito_explicit_auth_flows
  generate_client_secret      = var.cognito_generate_client_secret
  refresh_token_validity_days = var.cognito_refresh_token_validity_days
  tags                        = var.tags
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  vpc_id                     = var.vpc_id
  private_subnets            = var.private_subnets
  ecs_security_group_id      = var.ecs_security_group_id
  redis_node_type            = var.redis_node_type
  redis_engine_version       = var.redis_engine_version
  replication_group_id       = var.redis_replication_group_id
  description                = var.redis_description
  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  secret_name                = var.redis_secret_name
  secret_description         = var.redis_secret_description
  subnet_group_name          = var.redis_subnet_group_name
  security_group_name        = var.redis_security_group_name
  security_group_description = var.redis_security_group_description
  tags                       = var.tags
}

