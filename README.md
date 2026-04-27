# core-infra

IaC for the Investments Assistant project. Two Terraform modules manage all shared infrastructure:

| Module | What it owns |
| --- | --- |
| `terraform/aws` | S3 bucket for remote Terraform state |
| `terraform/github` | GitHub org, repositories, teams, environments, secrets |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.13
- [tflint](https://github.com/terraform-linters/tflint)
- [Poetry](https://python-poetry.org/) (for pre-commit)
- AWS credentials configured for the `investments-assistant-admin` profile

---

## First-time setup

```bash
# 1. Install local tooling (pre-commit hooks)
make install

# 2. Copy and fill in the var files for each module
cp terraform/aws/terraform.tfvars.example    terraform/aws/terraform.tfvars
cp terraform/github/terraform.tfvars.example terraform/github/terraform.tfvars
# Edit both files and fill in real values

# 3. Initialise providers and remote state
make init
```

---

## Common commands

```bash
make plan          # show all pending changes (safe, no writes)
make apply         # apply all changes (asks for confirmation)

make aws-plan      # plan only the AWS module
make github-apply  # apply only the GitHub module

make fmt           # auto-format Terraform code in place
make validate      # validate both modules
make lint          # run tflint on both modules
make pre-commit    # run all pre-commit hooks
```

Run `make help` to see every available target and the current variable values.

---

## Overriding variables

All key variables can be overridden on the command line:

```bash
make plan AWS_PROFILE=my-other-profile
make apply TF_WORKSPACE=staging
make github-plan TFVARS=staging.tfvars
```

---

## Module notes

### `terraform/aws`

Bootstraps the S3 bucket used as a Terraform state backend by both modules. Only needs to be applied once. Requires AWS credentials with S3 permissions.

### `terraform/github`

Manages the GitHub organisation, repositories, teams, branch protections, Actions environments, and secrets. Requires a GitHub personal access token or GitHub App credentials configured in the environment (`GITHUB_TOKEN`).

Secrets are supplied via `terraform/github/terraform.tfvars` (gitignored). See `terraform/github/terraform.tfvars.example` for the expected structure.

---

## State backend

Both modules store state in the S3 bucket created by the AWS module, with server-side encryption (KMS) and versioning enabled. The state files are:

| Module | S3 key |
| --- | --- |
| aws | `aws/invass-core-infra.tfstate` |
| github | `github/invass-core-infra.tfstate` |
