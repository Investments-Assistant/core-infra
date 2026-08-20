# core-infra

Infrastructure as Code for the Investments Assistant GitHub organisation. The
repository contains one OpenTofu stack:

| Module | What it owns |
| --- | --- |
| `opentofu/github` | GitHub organisation, repositories, teams, environments, secrets, and Actions variables |

OpenTofu state uses the local backend configured in
`opentofu/github/backend.tofu` and is stored in the module directory. State
files are ignored by Git and must be protected as sensitive data.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) ≥ 1.10
- [tflint](https://github.com/terraform-linters/tflint)
- [Poetry](https://python-poetry.org/) for pre-commit tooling
- A GitHub token with the permissions required by the provider

## First-time setup

```bash
# 1. Install local tooling and pre-commit hooks
make install

# 2. Copy and fill in the environment variables
cp opentofu/github/env.tfvars.example opentofu/github/prod.tfvars
# Edit prod.tfvars with real values

# 3. Initialise the local OpenTofu backend and provider
make init
```

## Common commands

```bash
make plan          # create a saved plan and JSON plan log
make apply         # apply the saved plan
make github-plan   # plan only the GitHub stack
make github-apply  # apply only the GitHub stack

make fmt           # format OpenTofu code in place
make validate      # validate the stack
make lint          # run tflint
make pre-commit    # run all pre-commit hooks
```

Run `make help` to see every target and the current variable values.

## Overriding variables

The environment/workspace prefix can be overridden on the command line:

```bash
make plan TF_ENV=staging
make github-plan TF_ENV=staging
```

## GitHub module

The GitHub stack manages organisation settings, repositories, teams, branch
protections, Actions environments, and secrets. Configure the provider with
`GITHUB_TOKEN`.

Secrets are supplied via `opentofu/github/$(TF_ENV).tfvars`, which is ignored by
Git. See `opentofu/github/env.tfvars.example` for the expected structure.
Runtime secrets such as broker API keys remain on the Raspberry Pi in its local
`.env` file by default.

## Local state

The backend is configured as:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

Do not commit state files or share them casually: OpenTofu state can contain
the plaintext values of sensitive variables. Back up local state securely if
you need recovery or migration support.
