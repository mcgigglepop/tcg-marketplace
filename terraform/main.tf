locals {
  functions = {
    post_confirmation = {
      function_name = "${var.lambda_function_name_prefix}-post-confirmation"
      handler       = var.lambda_handler != null ? var.lambda_handler : "index.handler"
      runtime       = var.lambda_runtime
      timeout       = var.lambda_timeout
      memory_size   = var.lambda_memory_size
      description   = var.lambda_description != "" ? var.lambda_description : "Post confirmation Lambda function"
      filename      = "${path.module}/../../../dist/zips/postConfirmation.zip"
      environment_variables = merge(
        var.lambda_environment_variables,
        { USER_TABLE = try(module.user_data_table[0].table_name, "") }
      )
    }
  }

  fn_arn    = { for k, m in module.lambda : k => m.function_arn }
  fn_name   = { for k, m in module.lambda : k => m.function_name }
  fn_invoke = { for k, m in module.lambda : k => m.invoke_arn }
}

# Cognito User Pool Module
module "cognito" {
  count = var.enable_cognito ? 1 : 0

  source = "./modules/cognito"

  user_pool_name               = var.user_pool_name
  client_name                  = var.cognito_client_name
  auto_verified_attributes     = var.cognito_auto_verified_attributes
  email_sending_account        = var.cognito_email_sending_account
  verification_email_option    = var.cognito_verification_email_option
  password_minimum_length      = var.cognito_password_minimum_length
  password_require_lowercase   = var.cognito_password_require_lowercase
  password_require_numbers     = var.cognito_password_require_numbers
  password_require_symbols     = var.cognito_password_require_symbols
  password_require_uppercase   = var.cognito_password_require_uppercase
  explicit_auth_flows          = var.cognito_explicit_auth_flows
  generate_client_secret       = var.cognito_generate_client_secret
  refresh_token_validity_days  = var.cognito_refresh_token_validity_days
  tags                         = var.tags
  allowed_oauth_flows          = var.cognito_allowed_oauth_flows
  allowed_oauth_scopes         = var.cognito_allowed_oauth_scopes
  callback_urls                = var.cognito_callback_urls
  logout_urls                  = var.cognito_logout_urls
  supported_identity_providers = var.cognito_supported_identity_providers
  domain_name           = var.cognito_domain_name
  post_confirmation_arn = try(module.lambda["post_confirmation"].function_arn, var.post_confirmation_arn)
}

# Redis Module
module "redis" {
  count = var.enable_redis ? 1 : 0

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

# Lambda Module
module "lambda" {
  source   = "./modules/lambda"
  for_each = local.functions

  function_name         = each.value.function_name
  role_arn              = var.lambda_role_arn
  handler               = each.value.handler
  runtime               = each.value.runtime
  timeout               = each.value.timeout
  memory_size           = each.value.memory_size
  description           = each.value.description
  package_type          = var.lambda_package_type
  filename              = try(each.value.filename, null)
  s3_bucket             = try(each.value.s3_bucket, var.lambda_s3_bucket)
  s3_key                = try(each.value.s3_key, var.lambda_s3_key)
  s3_object_version     = try(each.value.s3_object_version, var.lambda_s3_object_version)
  image_uri             = try(each.value.image_uri, var.lambda_image_uri)
  environment_variables = try(each.value.environment_variables, var.lambda_environment_variables)
  vpc_config            = try(each.value.vpc_config, var.lambda_vpc_config)
  dead_letter_target_arn = try(each.value.dead_letter_target_arn, var.lambda_dead_letter_target_arn)
  tracing_mode          = var.lambda_tracing_mode
  ephemeral_storage_size = var.lambda_ephemeral_storage_size
  tags                  = var.tags
}

