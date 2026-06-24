# core-infra

IaC for the Investments Assistant project. Two OpenTofu stacks manage all shared infrastructure:

| Module | What it owns |
| --- | --- |
| `opentofu/aws` | S3 bucket for remote OpenTofu state |
| `opentofu/github` | GitHub org, repositories, teams, environments, secrets, and Actions variables for the Pi deployment workflow |

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
cp opentofu/aws/env.tfvars.example    opentofu/aws/prod.tfvars
cp opentofu/github/env.tfvars.example opentofu/github/prod.tfvars
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

### `opentofu/aws`

Bootstraps the S3 bucket used as an OpenTofu state backend by both stacks. The
state bucket is private, versioned, encrypted with SSE-S3, uses S3 lock files,
and is the only AWS resource required by the Raspberry Pi strategy.

### `opentofu/github`

Manages the GitHub organisation, repositories, teams, branch protections, Actions environments, and secrets. Requires a GitHub personal access token or GitHub App credentials configured in the environment (`GITHUB_TOKEN`).

Secrets are supplied via `opentofu/github/$(TF_ENV).tfvars` (gitignored). See
`opentofu/github/env.tfvars.example` for the expected structure. The
GitHub stack can manage repository variables such as `PI_DEPLOY_DIR` for the
Pi self-hosted runner. Runtime secrets such as broker API keys remain in the
Pi's `.env` file by default; they do not need to be stored in GitHub Actions.

---

## State backend

Both stacks store state in the S3 bucket created by the AWS stack, with server-side encryption, versioning, and S3 lock files enabled. The state files are:

| Module | S3 key |
| --- | --- |
| aws | `aws/invass-core-infra.tfstate` |
| github | `github/invass-core-infra.tfstate` |
