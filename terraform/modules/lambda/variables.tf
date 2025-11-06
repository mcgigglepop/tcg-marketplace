variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN attached to the Lambda function"
  type        = string
}

variable "handler" {
  description = "Function entrypoint in your code (e.g., index.handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., nodejs20.x, python3.11, go1.x)"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Amount of time Lambda function has to run in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use"
  type        = number
  default     = 128
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "package_type" {
  description = "Lambda deployment package type (Zip or Image)"
  type        = string
  default     = "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be either 'Zip' or 'Image'."
  }
}

# Deployment package options (mutually exclusive)
variable "filename" {
  description = "Path to the function's deployment package (local zip file)"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket name containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI containing the function's deployment package (for Image package type)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_target_arn" {
  description = "ARN of an SQS queue or SNS topic for the dead letter queue"
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "Tracing mode (PassThrough, Active)"
  type        = string
  default     = "PassThrough"
  validation {
    condition     = contains(["PassThrough", "Active"], var.tracing_mode)
    error_message = "Tracing mode must be either 'PassThrough' or 'Active'."
  }
}

variable "ephemeral_storage_size" {
  description = "Amount of ephemeral storage (/tmp) in MB (512-10240)"
  type        = number
  default     = 512
  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "Ephemeral storage size must be between 512 and 10240 MB."
  }
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}
