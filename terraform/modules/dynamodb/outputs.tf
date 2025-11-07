output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.this.id
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.arn
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.this.stream_arn
}

output "table_stream_label" {
  description = "Label of the DynamoDB stream"
  value       = aws_dynamodb_table.this.stream_label
}

output "table_hash_key" {
  description = "Hash key attribute name"
  value       = aws_dynamodb_table.this.hash_key
}

output "table_range_key" {
  description = "Range key attribute name"
  value       = aws_dynamodb_table.this.range_key
}

