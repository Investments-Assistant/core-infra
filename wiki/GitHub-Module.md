# GitHub Module

Located at `opentofu/github/`.

Manages the entire **Investments-Assistant** GitHub organisation: settings, repositories,
files, teams, CI/CD environments, and repository-level Actions variables/secrets.

---

## Provider

```hcl
# providers.tofu
provider "github" {
  owner = "Investments-Assistant"
}
```

The GitHub provider authenticates via the `GITHUB_TOKEN` environment variable. Set it to
a fine-grained personal access token (or a GitHub App token) with admin:org and repo
permissions before running OpenTofu.

**Version**: `integrations/github ~> 6.0` — pins to the 6.x major version to avoid
breaking changes from provider upgrades.

---

## Organisation settings (`organization.tofu`)

```hcl
resource "github_organization_settings" "github_organization_settings" {
  billing_email = var.github_organization_email
  email         = var.github_organization_email
  name          = var.github_organization_name
  description   = var.github_organization_description
  lifecycle { prevent_destroy = true }
}
```

`prevent_destroy = true` means `tofu destroy` will fail with an error rather than
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
  opentofu_state: true

investments-assistant:
  description: "Main application codebase for Investments Assistant project"
  gitignore_template: "Python"
  opentofu_state: false
```

**Why YAML?** Storing repository definitions in YAML instead of directly in HCL makes
it easy to add a new repository without editing OpenTofu code — just add a new entry to
`repositories.yaml` and run `tofu apply`.

`locals.tofu` decodes this YAML:
```hcl
locals {
  repositories = {
    for name, repo in yamldecode(file("${path.module}/repositories.yaml")) :
    name => {
      name               = name
      description        = try(repo.description, null)
      gitignore_template = try(repo.gitignore_template, null)
      opentofu_state     = try(repo.opentofu_state, false)
    }
  }
}
```

`try()` handles optional YAML keys without failing.

---

## Repository settings (`repositories.tofu`)

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

Five files are managed by OpenTofu and pushed to every repository from shared templates:

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

`overwrite_on_create = true` means re-running `tofu apply` will update these files
in the repository if the template changes.

**Why manage these files via OpenTofu?** Ensures every repository has the same
baseline governance files without manually creating them. If you add a new repository to
`repositories.yaml`, it gets all five files automatically on the next apply.

---

## Teams (`teams.tofu`)

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

The `core` team is referenced in `environments.tofu` as a required reviewer for `prod`
deployments.

---

## Environments (`environments.tofu`)

Two environments are created on the `investments-assistant-raspberry-pi-5` repository:

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

Runtime secrets are not stored in GitHub environments. Broker keys, database passwords,
newsletter credentials, and model paths live in the Pi deployment directory's `.env`.
The GitHub environments are used for deployment governance only.

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

## Variables (`variables.tofu`)

| Variable | Type | Description |
|---|---|---|
| `github_organization_email` | string | Billing email for the org |
| `github_organization_name` | string | Display name |
| `github_organization_description` | string | Org description |
| `org_owners` | `set(string)` | GitHub usernames with admin rights |
| `repo_secrets` | `map(string)` | Repo-level secrets (all workflows) |
| `repo_variables` | `map(string)` | Repo-level variables for Pi deployment, e.g. `PI_DEPLOY_DIR` |

`repo_secrets` is marked `sensitive = true`. OpenTofu will not print values in
`plan` or `apply` output, but the plaintext still exists in state.

---

## Repository variables

The Pi deployment workflow reads `PI_DEPLOY_DIR` from repository variables. If unset,
the workflow defaults to `$HOME/investments-assistant` on the self-hosted runner.
