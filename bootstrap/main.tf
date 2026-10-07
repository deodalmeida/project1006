# The state bucket was created before this project, so it is imported into
# Terraform rather than created. After the first apply these import blocks
# are no-ops and can stay in place.
import {
  to = aws_s3_bucket.state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_versioning.state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.state
  id = var.state_bucket_name
}

import {
  to = aws_s3_bucket_public_access_block.state
  id = var.state_bucket_name
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Losing the state bucket means losing track of every managed resource.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning lets us recover a previous state file after corruption or a bad write.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# State can contain sensitive values, so encrypt it at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
