######################
# AWS Provider Variables
######################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

######################
# Common Variables
######################

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_cognito" {
  description = "Enable Cognito module (set via TF_VAR_enable_cognito environment variable)"
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Enable Redis module (set via TF_VAR_enable_redis environment variable)"
  type        = bool
  default     = false
}

######################
# # Cognito Variables
######################

variable "user_pool_name" {
  description = "Name for the Cognito User Pool"
  type        = string
}

variable "cognito_client_name" {
  description = "Name for the Cognito User Pool Client (defaults to {user_pool_name}-client if not set)"
  type        = string
  default     = null
}

variable "cognito_auto_verified_attributes" {
  description = "Attributes to automatically verify"
  type        = list(string)
  default     = ["email"]
}

variable "cognito_email_sending_account" {
  description = "Email sending account type (COGNITO_DEFAULT or DEVELOPER)"
  type        = string
  default     = "COGNITO_DEFAULT"
}

variable "cognito_verification_email_option" {
  description = "Verification email option (CONFIRM_WITH_CODE or CONFIRM_WITH_LINK)"
  type        = string
  default     = "CONFIRM_WITH_CODE"
}

variable "cognito_password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 8
}

variable "cognito_password_require_lowercase" {
  description = "Require lowercase characters in password"
  type        = bool
  default     = true
}

variable "cognito_password_require_numbers" {
  description = "Require numbers in password"
  type        = bool
  default     = true
}

variable "cognito_password_require_symbols" {
  description = "Require symbols in password"
  type        = bool
  default     = true
}

variable "cognito_password_require_uppercase" {
  description = "Require uppercase characters in password"
  type        = bool
  default     = true
}

variable "cognito_explicit_auth_flows" {
  description = "Explicit authentication flows to enable"
  type        = list(string)
  default = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}

variable "cognito_allowed_oauth_flows" {
  description = "Allowed OAuth flows"
  type        = list(string)
  default     = ["code"]
}

variable "cognito_allowed_oauth_scopes" {
  description = "Allowed OAuth scopes"
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "cognito_callback_urls" {
  description = "Callback URLs"
  type        = list(string)
  default     = ["https://oauth.pstmn.io/v1/callback"]
}

variable "cognito_logout_urls" {
  description = "Logout URLs"
  type        = list(string)
  default     = ["https://example.com"]
}

variable "cognito_supported_identity_providers" {
  description = "Supported identity providers"
  type        = list(string)
  default     = ["COGNITO"]
}

variable "cognito_generate_client_secret" {
  description = "Whether to generate a client secret"
  type        = bool
  default     = false
}

variable "cognito_refresh_token_validity_days" {
  description = "Number of days refresh tokens are valid"
  type        = number
  default     = 30
}

variable "cognito_domain_name" {
  description = "Domain name"
  type        = string
  default     = null
}

variable "post_confirmation_arn" {
  description = "ARN of the Lambda function to invoke after user confirmation"
  type        = string
  default     = null
}
######################
# Redis Variables
######################

variable "vpc_id" {
  description = "VPC ID where Redis will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for Redis subnet group"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group ID for ECS tasks that will access Redis"
  type        = string
}

variable "redis_node_type" {
  description = "Elasticache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_replication_group_id" {
  description = "Unique identifier for the Redis replication group"
  type        = string
}

variable "redis_description" {
  description = "Description for the Redis replication group"
  type        = string
  default     = "Redis replication group"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters in the replication group"
  type        = number
  default     = 1
}

variable "redis_automatic_failover_enabled" {
  description = "Whether automatic failover is enabled"
  type        = bool
  default     = false
}

variable "redis_secret_name" {
  description = "Name for the Secrets Manager secret storing Redis auth token"
  type        = string
}

variable "redis_secret_description" {
  description = "Description for the Secrets Manager secret"
  type        = string
  default     = "Redis AUTH token"
}

variable "redis_subnet_group_name" {
  description = "Name for the Elasticache subnet group"
  type        = string
}

variable "redis_security_group_name" {
  description = "Name for the Redis security group"
  type        = string
}

variable "redis_security_group_description" {
  description = "Description for the Redis security group"
  type        = string
  default     = "Security group for Redis cluster"
}

######################
# Lambda Variables
######################

variable "lambda_function_name_prefix" {
  description = "Prefix for Lambda function names (functions will be named {prefix}-{function-key})"
  type        = string
  default     = "tcg-marketplace"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (deprecated - use lambda_function_name_prefix instead)"
  type        = string
  default     = null
}

variable "lambda_role_arn" {
  description = "IAM role ARN attached to the Lambda function"
  type        = string
  default     = null
}

variable "lambda_handler" {
  description = "Function entrypoint in your code (e.g., index.handler)"
  type        = string
  default     = null
}

variable "lambda_runtime" {
  description = "Lambda runtime (e.g., nodejs20.x, python3.11, go1.x)"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout" {
  description = "Amount of time Lambda function has to run in seconds"
  type        = number
  default     = 3
}

variable "lambda_memory_size" {
  description = "Amount of memory in MB your Lambda function can use"
  type        = number
  default     = 128
}

variable "lambda_description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "lambda_package_type" {
  description = "Lambda deployment package type (Zip or Image)"
  type        = string
  default     = "Zip"
}

variable "lambda_filename" {
  description = "Path to the function's deployment package (local zip file)"
  type        = string
  default     = null
}

variable "lambda_s3_bucket" {
  description = "S3 bucket name containing the function's deployment package"
  type        = string
  default     = null
}

variable "lambda_s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "lambda_s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "lambda_image_uri" {
  description = "ECR image URI containing the function's deployment package (for Image package type)"
  type        = string
  default     = null
}

variable "lambda_environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "lambda_vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "lambda_dead_letter_target_arn" {
  description = "ARN of an SQS queue or SNS topic for the dead letter queue"
  type        = string
  default     = null
}

variable "lambda_tracing_mode" {
  description = "Tracing mode (PassThrough, Active)"
  type        = string
  default     = "PassThrough"
}

variable "lambda_ephemeral_storage_size" {
  description = "Amount of ephemeral storage (/tmp) in MB (512-10240)"
  type        = number
  default     = 512
}

