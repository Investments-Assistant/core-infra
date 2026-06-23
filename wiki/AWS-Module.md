# AWS Module

Located at `terraform/aws/`.

This module creates the private S3 bucket used as the OpenTofu remote-state backend
for `core-infra`. It does not deploy the Investment Assistant application.

---

## Resources

The module manages:

- `aws_s3_bucket.tf_states_buckets`
- `aws_s3_bucket_versioning.prod_tf_state_bucket_versioning`
- `aws_s3_bucket_server_side_encryption_configuration.encryption`
- `aws_s3_bucket_public_access_block.public_access`
- `aws_s3_bucket_lifecycle_configuration.aws_s3_terraform_state_bucket_lifecycle_configuration`

The bucket is private, versioned, encrypted with SSE-S3/AES256, and configured to
expire noncurrent versions after 90 days.

---

## Backend

Both `terraform/aws` and `terraform/github` use the same S3 bucket with different
state keys:

```hcl
terraform {
  backend "s3" {
    bucket       = "invass-core-infra-terraform-state-..."
    key          = "aws/invass-core-infra.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
    encrypt      = true
  }
}
```

`use_lockfile = true` uses S3 native lock files, so no DynamoDB table is required.

---

## Bootstrap

The AWS module creates the bucket that later stores its own state:

1. Initialise with local state for the first apply.
2. Apply `terraform/aws` to create the S3 bucket.
3. Configure `backend.tf`.
4. Run `tofu init -migrate-state`.

After this one-time bootstrap, both stacks use S3 state.
