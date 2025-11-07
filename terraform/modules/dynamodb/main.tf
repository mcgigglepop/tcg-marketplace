resource "aws_dynamodb_table" "marketplace" {
  name         = var.table_name
  billing_mode = var.billing_mode

  hash_key  = "PK"
  range_key = "SK"

  # --- Attributes (single-table keys + GSIs) ---
  attribute { 
    name = "PK"     
    type = "S" 
  }
  attribute { 
    name = "SK"     
    type = "S" 
  }
  attribute { 
    name = "GSI1PK" 
    type = "S" 
  }
  attribute { 
    name = "GSI1SK" 
    type = "S" 
  }
  attribute { 
    name = "GSI2PK" 
    type = "S" 
  }
  attribute { 
    name = "GSI2SK" 
    type = "S" 
  }

  # --- GSI1: lookup by email ---
  # GSI1PK = EMAIL#<lowercasedEmail>
  # GSI1SK = USER#<userID>
  global_secondary_index {
    name               = "GSI1"
    hash_key           = "GSI1PK"
    range_key          = "GSI1SK"
    projection_type    = "ALL"
  }

  # --- GSI2: by seller status for ops dashboards/review queues ---
  # GSI2PK = SELLER_STATUS#<status>   (draft|submitted|kyc_pending|verified|rejected)
  # GSI2SK = USER#<userID>
  global_secondary_index {
    name               = "GSI2"
    hash_key           = "GSI2PK"
    range_key          = "GSI2SK"
    projection_type    = "ALL"
  }

  # --- Resilience & security ---
  point_in_time_recovery { 
    enabled = true 
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = null # set to a CMK ARN if you want customer-managed key
  }

  # Optional: enable TTL for ephemeral items (e.g., sessions, temp tokens)
  ttl {
    attribute_name = "ttl" # store a Unix epoch seconds number on items you want auto-expired
    enabled        = true
  }

  tags = var.tags
}
