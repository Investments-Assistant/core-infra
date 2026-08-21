# Adding a Repository

Adding a new GitHub repository to the Investments-Assistant organisation is a
two-step process: add it to the YAML catalogue, then apply.

---

## Step 1: Add to `repositories.yaml`

Edit `opentofu/github/repositories.yaml`:

```yaml
core-infra:
  description: "Infrastructure as Code for Investments Assistant project"
  opentofu_state: true

investments-assistant:
  description: "Main application codebase"
  gitignore_template: "Python"
  opentofu_state: false

# Add your new repo here:
my-new-service:
  description: "A new microservice for the Investments Assistant project"
  gitignore_template: "Python"   # or another template name GitHub supports
  opentofu_state: false          # set to true if this repo also stores TF state
```

**Available `gitignore_template` values**: any template name from GitHub's
`.gitignore` template list — `Python`, `Go`, `Node`, `Java`, `Rust`, etc.
If `null`, no `.gitignore` is created (you'd add one manually).

**`opentofu_state`**: a custom attribute used for your own tracking — it doesn't
change the OpenTofu resources created. All repos get the same settings regardless.

---

## Step 2: Preview the changes

```bash
cd opentofu/github
export GITHUB_TOKEN=your_github_pat

tofu plan -var-file=prod.ttvars
```

You should see a plan that creates:
- 1 `github_repository` resource
- 5 `github_repository_file` resources (CODE_OF_CONDUCT, CODEOWNERS, CONTRIBUTING, LICENSE, README.md)

Example plan output:
```
# module.github_repositories.github_repository.repositories["my-new-service"] will be created
+ resource "github_repository" "repositories" {
    + name        = "my-new-service"
    + description = "A new microservice for the Investments Assistant project"
    ...
}

# module.github_repositories.github_repository_file.readme["my-new-service"] will be created
+ resource "github_repository_file" "readme" {
    + file    = "README.md"
    + content = "# my-new-service\n\nA new microservice..."
}
...
```

---

## Step 3: Apply

```bash
tofu apply -var-file=prod.ttvars
```

OpenTofu creates the GitHub repository and pushes all five standard files.

---

## Standard files that every repo gets

| File | Content |
|---|---|
| `CODE_OF_CONDUCT` | Contributor Covenant code of conduct |
| `CODEOWNERS` | `* @org_owner1, @org_owner2` — all org owners are code owners |
| `CONTRIBUTING` | Fork → branch → PR workflow instructions |
| `LICENSE` | MIT License |
| `README.md` | `# repo-name\n\n{description}` placeholder |

These are managed by OpenTofu. If you edit them manually on GitHub, the next
`tofu apply` will overwrite your changes (because `overwrite_on_create = true`).
To customise: either update the template in `files_templates/` (affects all repos) or
stop managing the file with OpenTofu (remove the `github_repository_file` resource for
that specific file/repo).

---

## Granting repo access to the `core` team

Repository access is not currently managed by OpenTofu — the `core` team has access
via org membership. If you need to grant access to a specific team, add:

```hcl
# In teams.tofu or a new file
resource "github_team_repository" "core_my_new_service" {
  team_id    = github_team.core.id
  repository = "my-new-service"
  permission = "maintain"
}
```

---

## Branch protection

Branch protection rules are not yet managed by OpenTofu. To add them manually (or via
OpenTofu with `github_branch_protection`):

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.repositories["my-new-service"].node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
  }

  required_status_checks {
    strict   = true
    contexts = ["Unit Tests"]  # must match the GitHub Actions job name
  }

  enforce_admins = false
}
```

---

## Removing a repository

**Do not remove a repository from `repositories.yaml` and run `tofu apply`.**
Because `prevent_destroy = true` is set on the repository module's
`github_repository`, OpenTofu will refuse
to delete the resource:

```
Error: Instance cannot be destroyed
  Resource github_repository.repositories["my-service"] has
  lifecycle.prevent_destroy set, but the plan calls for this resource to be destroyed.
```

To intentionally delete a repository:
1. Remove `prevent_destroy = true` from the resource temporarily
2. Remove the entry from `repositories.yaml`
3. Run `tofu apply`
4. Re-add `prevent_destroy = true`

Alternatively, archive the repository on GitHub (sets it read-only) rather than deleting it.
