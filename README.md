# core-infra

IaC for the Investments Assistant project. Two OpenTofu stacks manage all shared infrastructure:

| Module | What it owns |
| --- | --- |
| `terraform/aws` | S3 bucket for remote OpenTofu state and GitHub Actions AWS OIDC IAM roles |
| `terraform/github` | GitHub org, repositories, teams, environments, secrets, and Actions variables |

---

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) ≥ 1.10
- [tflint](https://github.com/terraform-linters/tflint)
- [Poetry](https://python-poetry.org/) (for pre-commit)
- AWS credentials configured for the `investments-assistant-admin` profile

---

## First-time setup

```bash
# 1. Install local tooling (pre-commit hooks)
make install

# 2. Copy and fill in the var files for each module
cp terraform/aws/env.tfvars.example    terraform/aws/prod.tfvars
cp terraform/github/env.tfvars.example terraform/github/prod.tfvars
# Edit both files and fill in real values

# 3. Initialise providers and remote state
make init
```

---

## Common commands

```bash
make plan          # create saved plans and JSON plan logs
make apply         # apply all changes using the saved plan

make aws-plan      # plan only the AWS module
make github-apply  # apply only the GitHub module

make fmt           # auto-format OpenTofu code in place
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
make apply TF_ENV=staging
make github-plan TF_ENV=staging
```

---

## Module notes

### `terraform/aws`

Bootstraps the S3 bucket used as an OpenTofu state backend by both stacks and
creates the AWS IAM roles used by GitHub Actions OIDC:

- `investments-assistant-github-actions-build-role`: can push service images to
  the `investments-*` ECR repositories.
- `investments-assistant-github-actions-deploy-role`: can read the
  `investments-assistant-k8s` OpenTofu state, describe the EKS cluster, and
  update the Route 53 alias used by the public ALB.

The roles trust only the configured GitHub repository and branches through
`token.actions.githubusercontent.com`.

### `terraform/github`

Manages the GitHub organisation, repositories, teams, branch protections, Actions environments, and secrets. Requires a GitHub personal access token or GitHub App credentials configured in the environment (`GITHUB_TOKEN`).

Secrets are supplied via `terraform/github/$(TF_ENV).tfvars` (gitignored). See
`terraform/github/env.tfvars.example` for the expected structure. The
GitHub stack creates repository variables named `AWS_BUILD_ROLE_ARN` and
`AWS_DEPLOY_ROLE_ARN` for the workflow repositories, populated from the AWS
stack outputs `github_actions_build_role_arn` and
`github_actions_deploy_role_arn`. Apply the AWS stack before the GitHub stack.

---

## State backend

Both stacks store state in the S3 bucket created by the AWS stack, with server-side encryption (KMS), versioning, and S3 lock files enabled. The state files are:

| Module | S3 key |
| --- | --- |
| aws | `aws/invass-core-infra.tfstate` |
| github | `github/invass-core-infra.tfstate` |
