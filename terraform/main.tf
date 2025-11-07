locals {
  functions = {
    post_confirmation = {
      zip = "${path.module}/../dist/zips/postConfirmation.zip"
      env = { USER_TABLE = module.dynamodb.table_name }
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
  domain_name                  = var.cognito_domain_name
  # post_confirmation_arn        = try(module.lambda["post_confirmation"].function_arn, var.post_confirmation_arn)
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

module "dynamodb" {
  source = "./modules/dynamodb"
  table_name = var.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode
  tags = var.tags
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.application_name}_lambda_exec_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_log_access" {
  name = "${var.application_name}_lambda_log_access_${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_access_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_log_access.arn
}

resource "aws_iam_policy" "dynamodb_access" {
  name = "${var.application_name}_lambda_dynamo_access_${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"],
        Resource = module.dynamodb.table_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

module "lambda" {
  source   = "./modules/lambda"
  for_each = local.functions
  name     = "${var.application_name}-${each.key}-${var.environment}"
  role_arn = aws_iam_role.lambda_exec_role.arn
  zip_path = each.value.zip
  handler  = "index.handler"
  env      = each.value.env
  tags     = var.tags
}