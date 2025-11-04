# AWS Provider Variables
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Common Variables
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Cognito Variables
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

# Redis Variables
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

