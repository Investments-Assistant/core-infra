resource "aws_s3_bucket" "prod_tf_state_bucket" {
  bucket = var.prod_tf_state_bucket_name
  tags = {
    Terraform_State        = true
    Environment = "prod"
  }
}

resource "aws_s3_bucket_versioning" "prod_tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_s3_terraform_state_bucket_lifecycle_configuration" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  rule {
    id = "expire-old-versions"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
