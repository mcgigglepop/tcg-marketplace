terraform {
  backend "s3" {
    bucket = "terraform-state-files-x283"
    key    = "tcg-marketplace/terraform.tfstate"
    region = "us-west-2"

    # Enable state locking with DynamoDB
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}