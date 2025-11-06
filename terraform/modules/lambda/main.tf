resource "aws_lambda_function" "this" {
  function_name    = var.name
  role             = var.role_arn
  filename         = var.zip_path
  handler          = var.handler
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256(var.zip_path)

  environment {
    variables = var.env
  }

  tags = var.tags
}