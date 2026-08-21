# core-infra

Infrastructure as Code for the Investments Assistant GitHub organisation. The
repository contains one OpenTofu root stack that composes four reusable GitHub
modules from `opentofu-modules`:

| Module | What it owns |
| --- | --- |
| `opentofu/github` | Root state, provider configuration, repository catalogue, and composition of the GitHub modules |
| `github/organization` | Organization settings and administrator memberships |
| `github/repositories` | Repositories, security features, vulnerability alerts, and optional governance files |
| `github/team` | Core team and optional team memberships |
| `github/environments` | Deployment environments, branch policies, Actions secrets, and variables |

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
cp opentofu/github/env.ttvars.example opentofu/github/prod.ttvars
# Edit prod.ttvars with real values

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

## GitHub modules

The reusable implementation is split into `github/organization`,
`github/repositories`, `github/team`, and `github/environments` modules in the
`Investments-Assistant/opentofu-modules` repository. Each module has a focused
responsibility and can be used independently; the root stack composes all four.
Boolean inputs such as `manage_settings`, `manage_repository_files`,
`create_team`, and `manage_environments` let consumers opt into only the
resources they need. Configure the provider with `GITHUB_TOKEN`.

The module source currently tracks `main` while the extraction is published;
replace it with a release tag such as `v1.1.0` once that module version exists.

Secrets are supplied via `opentofu/github/$(TF_ENV).ttvars`, which is ignored by
Git. See `opentofu/github/env.ttvars.example` for the expected structure.
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
