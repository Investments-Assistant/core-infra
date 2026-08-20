# State Management

The GitHub OpenTofu stack uses the local backend configured in
`opentofu/github/backend.tofu`:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

State remains on the machine where OpenTofu runs. It is excluded from source
control by the repository's `.gitignore`.

## State file locations

For the default workspace, OpenTofu stores state at:

```text
opentofu/github/terraform.tfstate
```

Additional workspaces use OpenTofu's local workspace state directories. The
workspace name is selected by `TF_ENV`, which defaults to `prod` in the root
Makefile:

```bash
make init TF_ENV=prod
make plan TF_ENV=prod
```

Use separate workspaces for separate environments so their state remains
isolated.

## Locking

The local backend locks state during operations. Do not run concurrent
`tofu apply` commands against the same workspace. If an operation is
interrupted, rerun the command after confirming that no other OpenTofu process
is using the workspace.

## Viewing state

```bash
cd opentofu/github
tofu state list
tofu state show 'github_repository.repositories["investments-assistant-raspberry-pi-5"]'
tofu show -json
```

## Initialising a new environment

```bash
# From the repository root
make install
cp opentofu/github/env.tfvars.example opentofu/github/prod.tfvars
# Edit prod.tfvars with organisation details and secrets

export GITHUB_TOKEN=...
make init
make plan
make apply
```

For another environment, use a separate `TF_ENV` value and matching tfvars
file, for example `staging.tfvars`.

## Backups and sensitive values

OpenTofu state can contain plaintext values for sensitive variables. Protect
the state file with normal local filesystem permissions and store any backups
in an encrypted, access-controlled location. Never commit state files,
tfvars files, or state backups to the repository.
