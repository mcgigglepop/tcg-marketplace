variable "vpc_id" {
  description = "VPC ID where Elasticache will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for Elasticache subnet group"
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

variable "replication_group_id" {
  description = "Unique identifier for the Redis replication group"
  type        = string
}

variable "description" {
  description = "Description for the Redis replication group"
  type        = string
  default     = "Redis replication group"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters in the replication group"
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled"
  type        = bool
  default     = false
}

variable "secret_name" {
  description = "Name for the Secrets Manager secret storing Redis auth token"
  type        = string
}

variable "secret_description" {
  description = "Description for the Secrets Manager secret"
  type        = string
  default     = "Redis AUTH token"
}

variable "subnet_group_name" {
  description = "Name for the Elasticache subnet group"
  type        = string
}

variable "security_group_name" {
  description = "Name for the Redis security group"
  type        = string
}

variable "security_group_description" {
  description = "Description for the Redis security group"
  type        = string
  default     = "Security group for Redis cluster"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}