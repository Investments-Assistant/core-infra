# State Management

Both OpenTofu modules (`aws/` and `github/`) store their state in the same S3 bucket
with different **state keys** (paths within the bucket).

OpenTofu state is tiny, so this S3 usage should stay effectively free or
near-zero cost when you remain inside the current AWS Free Tier/credit limits.
Keep the bucket private, do not use it for backups or app data, and keep old
state versions bounded so storage cannot grow unnoticed.

---

## State file locations

| Module | S3 key |
|---|---|
| `opentofu/aws/` | `aws/invass-core-infra.tfstate` |
| `opentofu/github/` | `github/invass-core-infra.tfstate` |

Both state files live in:
```
s3://invass-core-infra-opentofu-state-20251026205837245600000001/
    aws/invass-core-infra.tfstate
    github/invass-core-infra.tfstate
```

---

## Why separate state files per module?

Each OpenTofu working directory (`aws/` and `github/`) has its own state file.
This gives module-level blast radius isolation:
- A misconfiguration in `github/` cannot corrupt `aws/` state
- `tofu plan` in `aws/` only shows changes to AWS resources
- Different team members (or CI jobs) can work on different modules concurrently

If they shared a state file, every `tofu plan` would need to refresh all resources
in both AWS and GitHub, slowing down the feedback loop and increasing the chance of
accidental cross-module changes.

---

## State locking

OpenTofu's S3 backend with `use_lockfile = true` creates a lock by writing a small
`.tflock` file using S3's conditional write (If-None-Match: *). If another `tofu apply`
is running, the lock file already exists and the second run fails with:

```
Error: Error acquiring the state lock
```

This prevents two simultaneous `tofu apply` runs from corrupting the state file.

The lock is automatically released when `tofu apply` completes. If a run crashes
and leaves a lock, you can manually remove it:
```bash
aws s3 rm s3://invass-core-infra-opentofu-state-.../github/invass-core-infra.tfstate.tflock
```

---

## Viewing state

```bash
# List all resources in a module's state
cd opentofu/github
tofu state list

# Show details of a specific resource
tofu state show github_repository.repositories["investments-assistant"]

# Show entire state as JSON
tofu show -json
```

---

## State backup and restore

Because versioning is enabled on the S3 bucket, previous versions of state files are
kept for rollback. The bucket lifecycle expires noncurrent versions after 90 days
to avoid unbounded storage growth. To restore a previous state:

```bash
# List all versions of the github state file
aws s3api list-object-versions \
  --bucket invass-core-infra-opentofu-state-20251026205837245600000001 \
  --prefix github/invass-core-infra.tfstate

# Download a specific version
aws s3api get-object \
  --bucket invass-core-infra-opentofu-state-20251026205837245600000001 \
  --key github/invass-core-infra.tfstate \
  --version-id <VERSION_ID> \
  invass-core-infra-restored.tfstate

# Restore: overwrite current state with the old version
tofu state push invass-core-infra-restored.tfstate
```

---

## Initialising a new environment

If you're setting up the project from scratch on a new machine:

```bash
# 1. Set AWS credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

# 2. Set GitHub token
export GITHUB_TOKEN=...

# 3. Bootstrap the AWS module (first time only — uses local state initially)
cd opentofu/aws
tofu init
tofu apply -var-file=prod.tfvars
# ← Creates the S3 bucket

# 4. Migrate AWS module state to S3
# Edit backend.tf to enable S3 backend, then:
tofu init -migrate-state

# 5. Init and apply the GitHub module
cd ../github
cp env.tfvars.example prod.tfvars
# Edit prod.tfvars with your org details and secrets
tofu init
tofu apply -var-file=prod.tfvars
```

---

## Secrets in state

OpenTofu state contains the plaintext values of all `sensitive` variables (secrets).
The state is protected by:
1. **S3 private access**: public access block is enabled; the bucket is not publicly readable
2. **S3 encryption at rest**: SSE-S3 / AES-256 bucket default encryption
3. **Backend encryption flag**: `encrypt = true` in the backend config requests encrypted state objects

Anyone with access to the S3 bucket can read the state file and extract secrets. Control
access via IAM policies: only the developer's IAM user and any CI/CD roles should have
`s3:GetObject` / `s3:PutObject` on the state bucket.
