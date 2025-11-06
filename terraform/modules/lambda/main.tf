resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  description   = var.description

  # Deployment package configuration
  package_type = var.package_type

  # Zip package deployment (for package_type = "Zip")
  filename          = var.package_type == "Zip" && var.filename != null ? var.filename : null
  s3_bucket         = var.package_type == "Zip" && var.s3_bucket != null ? var.s3_bucket : null
  s3_key            = var.package_type == "Zip" && var.s3_key != null ? var.s3_key : null
  s3_object_version = var.package_type == "Zip" && var.s3_object_version != null ? var.s3_object_version : null
  source_code_hash  = var.package_type == "Zip" && var.filename != null ? filebase64sha256(var.filename) : null

  # Image package deployment (for package_type = "Image")
  image_uri = var.package_type == "Image" && var.image_uri != null ? var.image_uri : null

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter queue configuration
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # Tracing configuration
  tracing_config {
    mode = var.tracing_mode
  }

  # Ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  tags = var.tags
}