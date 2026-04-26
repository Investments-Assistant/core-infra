# AWS Module

Located at `terraform/aws/`.

Creates and manages the **S3 bucket** that stores Terraform remote state for all modules
in the `core-infra` project.

---

## Why AWS for state storage?

Terraform state must be stored somewhere durable and accessible to anyone running
`terraform apply`. Options considered:

| Option | Pros | Cons |
|---|---|---|
| **Local state** | Zero setup | Lost if disk dies; not shareable; no locking |
| **Git** | Version history | Secrets in state file committed to repo; no locking |
| **Terraform Cloud** | Managed, built-in UI | Requires a Terraform Cloud account |
| **S3 + native locking** | Durable, cheap, AWS-native | Requires an AWS account |

S3 was chosen because:
- The project already has an AWS account for this purpose
- S3 is essentially free for the tiny state files involved (< 1 MB)
- Terraform's S3 backend supports **native state locking** via S3 object conditional
  writes (no DynamoDB table needed — `use_lockfile = true`)
- State is stored in the same region as the organisation (EU South 2, Spain)

---

## Provider

```hcl
# providers.tf
provider "aws" {
  region = "eu-south-2"   # AWS Spain region (eu-south-2)
}
```

**Why `eu-south-2` (AWS Spain)?** This is the AWS region closest to Portugal/Spain,
minimising latency for Terraform state operations. It also means data stays within the
EU for GDPR compliance.

Authentication uses the default AWS credential chain: `~/.aws/credentials`,
environment variables (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`), or an IAM role.

---

## S3 bucket (`resources.tf`)

### Bucket creation

```hcl
resource "aws_s3_bucket" "prod_tf_state_bucket" {
  bucket = var.prod_tf_state_bucket_name
  tags = {
    Terraform_State = true
    Environment     = "prod"
  }
}
```

The bucket name is passed in via `var.prod_tf_state_bucket_name` (from `terraform.tfvars`).
The actual name is `invass-core-infra-terraform-state-20251026205837245600000001` — this
was generated with a random suffix to ensure global uniqueness (S3 bucket names are
globally unique across all AWS accounts).

### Versioning

```hcl
resource "aws_s3_bucket_versioning" "prod_tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  versioning_configuration { status = "Enabled" }
}
```

Versioning keeps every version of the state file. This allows you to roll back to a
previous state if `terraform apply` produces an unintended change. You can restore an old
state version from the S3 console or via `aws s3api get-object --version-id`.

### Encryption

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.prod_tf_state_bucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

State files contain secrets (API keys, database passwords) encrypted by Terraform's own
encryption layer, but an additional layer of AWS KMS encryption at rest is applied at
the S3 level. `bucket_key_enabled = true` reduces the number of KMS API calls by caching
the data key per bucket — saves cost and reduces latency.

### Public access block

```hcl
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.prod_tf_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

All four public access settings are blocked. This prevents the state bucket from ever
being accidentally made public (e.g. via a bucket policy that inadvertently grants public
read access). State files contain secrets; public access must be impossible.

### Lifecycle configuration

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "..." {
  rule {
    id = "expire-old-versions"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "INTELLIGENT_TIERING"
    }
  }
}
```

After 30 days, non-current (old) versions of the state file transition to
**S3 Intelligent-Tiering**, which automatically moves objects between access tiers based
on access frequency. For state file history (rarely accessed after 30 days), this is
cheaper than Standard storage (~40% cost reduction for infrequently accessed objects).

There is no expiration rule — old state versions are kept indefinitely for rollback
capability. The cost is negligible (state files are < 100 KB each).

---

## Backend (`backend.tf`)

```hcl
terraform {
  backend "s3" {
    bucket       = "invass-core-infra-terraform-state-20251026205837245600000001"
    key          = "aws/invass-core-infra.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
    encrypt      = true
  }
}
```

**Bootstrapping problem**: the AWS module creates the S3 bucket that it also uses as its
own backend. This is a chicken-and-egg problem. The solution:

1. First run: use local state (`terraform init` with no backend configured, or a temporary
   `backend "local" {}`)
2. Create the bucket: `terraform apply` creates the S3 bucket
3. Migrate state: update `backend.tf` to the S3 backend and run `terraform init -migrate-state`
4. All future runs use S3 state

This one-time bootstrapping is only needed when setting up from scratch.

**`use_lockfile = true`**: uses S3 object conditional writes for state locking (new in
Terraform 1.10+). No DynamoDB table is required. The lock is a small file at
`<key>.tflock` in the same bucket.

**`encrypt = true`**: enables client-side encryption of the state file in addition to
the S3-level KMS encryption.

---

## Variables (`variables.tf`)

| Variable | Type | Description |
|---|---|---|
| `prod_tf_state_bucket_name` | string | The globally unique S3 bucket name |

Set in `terraform.tfvars`:
```hcl
prod_tf_state_bucket_name = "invass-core-infra-terraform-state-20251026205837245600000001"
```
