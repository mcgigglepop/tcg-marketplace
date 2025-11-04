variable "vpc_id" {
  description = "VPC where ECS and Elasticache live"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for Elasticache"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group ID for ECS tasks"
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