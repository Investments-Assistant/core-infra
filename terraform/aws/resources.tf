resource "aws_s3_bucket" "tf_states_buckets" {
  for_each = toset(var.tf_state_buckets_names)
  bucket   = each.value
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Terraform_State = true
    Environment     = "prod"
  }
}

resource "aws_s3_bucket_versioning" "prod_tf_state_bucket_versioning" {
  for_each = aws_s3_bucket.tf_states_buckets
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = aws_s3_bucket.tf_states_buckets
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each                = aws_s3_bucket.tf_states_buckets
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_s3_terraform_state_bucket_lifecycle_configuration" {
  for_each = aws_s3_bucket.tf_states_buckets
  bucket   = each.value.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
