output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "ARN to be used for invoking Lambda function from API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN (ARN with version) of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "last_modified" {
  description = "Date this resource was last modified"
  value       = aws_lambda_function.this.last_modified
}