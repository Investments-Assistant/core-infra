# GitHub Module

Located at `terraform/github/`.

Manages the entire **Investments-Assistant** GitHub organisation: settings, repositories,
files, teams, and CI/CD environments.

---

## Provider

```hcl
# providers.tf
provider "github" {
  owner = "Investments-Assistant"
}
```

The GitHub provider authenticates via the `GITHUB_TOKEN` environment variable. Set it to
a fine-grained personal access token (or a GitHub App token) with admin:org and repo
permissions before running Terraform.

**Version**: `integrations/github ~> 6.0` — pins to the 6.x major version to avoid
breaking changes from provider upgrades.

---

## Organisation settings (`organization.tf`)

```hcl
resource "github_organization_settings" "github_organization_settings" {
  billing_email = var.github_organization_email
  email         = var.github_organization_email
  name          = var.github_organization_name
  description   = var.github_organization_description
  lifecycle { prevent_destroy = true }
}
```

`prevent_destroy = true` means `terraform destroy` will fail with an error rather than
deleting the org settings resource. This is a safety guard — accidentally running destroy
cannot nuke the organisation configuration.

Org membership:
```hcl
resource "github_membership" "owners" {
  for_each = var.org_owners  # set(string) of GitHub usernames
  username = each.value
  role     = "admin"
  lifecycle { prevent_destroy = true }
}
```

All members in `org_owners` are granted `admin` role. For a small personal project with
one owner, this is fine. For a larger team, you'd separate owners from members.

---

## Repository catalogue (`repositories.yaml`)

```yaml
core-infra:
  description: "Infrastructure as Code for Investments Assistant project"
  gitignore_template: "Terraform"
  terraform_state: true

investments-assistant:
  description: "Main application codebase for Investments Assistant project"
  gitignore_template: "Python"
  terraform_state: false
```

**Why YAML?** Storing repository definitions in YAML instead of directly in HCL makes
it easy to add a new repository without editing Terraform code — just add a new entry to
`repositories.yaml` and run `terraform apply`.

`locals.tf` decodes this YAML:
```hcl
locals {
  repositories = {
    for name, repo in yamldecode(file("${path.module}/repositories.yaml")) :
    name => {
      name               = name
      description        = try(repo.description, null)
      gitignore_template = try(repo.gitignore_template, null)
      terraform_state    = try(repo.terraform_state, false)
    }
  }
}
```

`try()` handles optional YAML keys without failing.

---

## Repository settings (`repositories.tf`)

All repositories are created with the same security settings:

```hcl
resource "github_repository" "repositories" {
  for_each = local.repositories
  ...
  allow_merge_commit         = false   # squash or rebase only
  allow_rebase_merge         = false   # squash only
  delete_branch_on_merge     = true    # auto-delete feature branches
  vulnerability_alerts       = true    # Dependabot alerts
  allow_update_branch        = true    # "Update branch" button in PRs
  security_and_analysis {
    secret_scanning               { status = "enabled" }
    secret_scanning_push_protection { status = "enabled" }
  }
  lifecycle { prevent_destroy = true }
}
```

**Why `allow_merge_commit = false` and `allow_rebase_merge = false`?**
Only squash merges are allowed. This keeps the default branch history clean and linear —
each PR becomes a single commit with a descriptive title.

**Secret scanning push protection**: GitHub will refuse a `git push` if it detects a
secret pattern (API key, private key, etc.) in the diff. This prevents accidental secret
exposure before it reaches the remote.

### Standard files

Five files are managed by Terraform and pushed to every repository from shared templates:

| File | Template | Content |
|---|---|---|
| `CODE_OF_CONDUCT` | `files_templates/CODE_OF_CONDUCT_template` | Standard contributor code of conduct |
| `CODEOWNERS` | `files_templates/CODEOWNERS_template` | Auto-approve bot; all owners as reviewers |
| `CONTRIBUTING` | `files_templates/CONTRIBUTING_template` | How to contribute (fork, branch, PR) |
| `LICENSE` | `files_templates/LICENSE_template` | MIT License |
| `README.md` | `files_templates/README_template` | Title + description placeholder |

`CODEOWNERS` uses `templatefile()` to inject the org owners list:
```hcl
content = templatefile("${path.module}/files_templates/CODEOWNERS_template", {
  codeowners = join(", ", var.org_owners)
})
```

`overwrite_on_create = true` means re-running `terraform apply` will update these files
in the repository if the template changes.

**Why manage these files via Terraform?** Ensures every repository has the same
baseline governance files without manually creating them. If you add a new repository to
`repositories.yaml`, it gets all five files automatically on the next apply.

---

## Teams (`teams.tf`)

```hcl
resource "github_team" "core" {
  name    = "core"
  privacy = "closed"
  lifecycle { prevent_destroy = true }
}

resource "github_team_membership" "core_owners" {
  for_each = var.org_owners
  team_id  = github_team.core.id
  username = each.value
  role     = "maintainer"
  lifecycle { prevent_destroy = true }
}
```

The `core` team has `privacy = "closed"` — visible to org members but not to the public.
All members of `org_owners` are added as team `maintainer` (not just `member`), giving
them admin rights over the team.

The `core` team is referenced in `environments.tf` as a required reviewer for `prod`
deployments.

---

## Environments (`environments.tf`)

Two environments are created on the `investments-assistant` repository:

### `dev` — permissive
- No required reviewers
- `wait_timer = 0` — deploys immediately after trigger
- `custom_branch_policies = true` + a wildcard branch policy (`*`) — any branch can deploy to dev

### `prod` — protected
- Requires review by the `core` team
- `wait_timer = 5` minutes — after approval, there's a 5-minute window to cancel
- `protected_branches = true` — only the default branch (main/master) can deploy to prod

This two-environment structure is standard GitOps practice:
- Developers can freely deploy to `dev` from feature branches for testing
- Prod deployments require a human approval step, protecting against accidental auto-merges

### Environment secrets and variables

Secrets and variables are defined in `terraform.tfvars` (gitignored):

```hcl
dev_secrets = {
  ALPACA_API_KEY    = "PKtest..."
  POSTGRES_PASSWORD = "devpassword"
}

dev_variables = {
  LLM_MODEL_PATH = "/app/models/qwen2.5-3b-instruct-q8_0.gguf"  # smaller model for dev
}

prod_secrets = {
  ALPACA_API_KEY    = "PKlive..."
  POSTGRES_PASSWORD = "strongpassword"
}
```

`locals.tf` flattens these nested maps into a single-level map with composite keys
(`"dev__ALPACA_API_KEY"`) for use with `for_each`. This is a common Terraform pattern
for iterating over nested structures.

### Repository-level secrets

Secrets that span both environments (e.g. `SONAR_TOKEN` for SonarCloud) are stored as
repository-level secrets:

```hcl
variable "repo_secrets" {
  description = "Repository-level Actions secrets shared across all environments"
  type        = map(string)
  sensitive   = true
  default     = {}
}
```

`SONAR_TOKEN` is the primary use case — the SonarCloud token is the same for both dev
and prod workflows.

---

## Variables (`variables.tf`)

| Variable | Type | Description |
|---|---|---|
| `github_organization_email` | string | Billing email for the org |
| `github_organization_name` | string | Display name |
| `github_organization_description` | string | Org description |
| `org_owners` | `set(string)` | GitHub usernames with admin rights |
| `dev_secrets` | `map(string)` | Sensitive env secrets for `dev` |
| `dev_variables` | `map(string)` | Non-sensitive env vars for `dev` |
| `prod_secrets` | `map(string)` | Sensitive env secrets for `prod` |
| `prod_variables` | `map(string)` | Non-sensitive env vars for `prod` |
| `repo_secrets` | `map(string)` | Repo-level secrets (all workflows) |

All `*_secrets` variables are marked `sensitive = true`. Terraform will not print their
values in `plan` or `apply` output, and will redact them in state file display.

---

## Pre-built non-sensitive variables

`locals.tf` pre-populates both `dev` and `prod` environments with configuration that
doesn't need to be kept secret:

```hcl
dev = {
  variables = merge({
    ENVIRONMENT            = "development"
    TRADING_MODE           = "recommend"
    LLM_BACKEND            = "llama_cpp"
    NEWSLETTER_IMAP_SERVER = "imap.gmail.com"
    NEWSLETTER_IMAP_PORT   = "993"
    ...
  }, var.dev_variables)
}

prod = {
  variables = merge({
    ENVIRONMENT  = "production"
    TRADING_MODE = "auto"     # prod runs in auto mode
    ...
  }, var.prod_variables)
}
```

Note `TRADING_MODE = "auto"` in prod — the production environment defaults to autonomous
trading mode. This is a deliberate choice for a "set and forget" home assistant; change
to `"recommend"` in `locals.tf` if you prefer manual confirmation in production.
