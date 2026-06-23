# ── GitHub Environments ────────────────────────────────────────────────────────
#
# Creates `dev` and `prod` environments on the investments-assistant repository.
# Runtime secrets stay in the Raspberry Pi `.env`; GitHub environments are used
# only for deployment governance.
# ──────────────────────────────────────────────────────────────────────────────

resource "github_repository_environment" "app_envs" {
  for_each    = local.environments
  repository  = local.app_repo
  environment = each.key

  # PROD requires a manual review from a core-team member before any deployment
  dynamic "reviewers" {
    for_each = each.key == "prod" ? [1] : []
    content {
      teams = [github_team.core.id]
    }
  }

  # PROD waits 5 minutes after approval — gives time to cancel accidental deploys
  wait_timer = each.key == "prod" ? 5 : 0

  deployment_branch_policy {
    protected_branches     = each.key == "prod" ? true : false
    custom_branch_policies = each.key == "prod" ? false : true
  }

  depends_on = [github_repository.repositories]
}

# Allow DEV to deploy from any branch (useful for feature-branch testing)
resource "github_repository_environment_deployment_policy" "dev_any_branch" {
  repository     = local.app_repo
  environment    = "dev"
  branch_pattern = "*"

  depends_on = [github_repository_environment.app_envs]
}

# ── Repository-level secrets (shared across all workflows/environments) ────────

resource "github_actions_secret" "repo_secrets" {
  for_each    = local.repo_secrets_flat
  repository  = local.app_repo
  secret_name = each.value.name
  value       = each.value.value

  depends_on = [github_repository.repositories]
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_actions_variable" "repo_variables" {
  for_each      = local.repo_variables_flat
  repository    = local.app_repo
  variable_name = each.value.name
  value         = each.value.value

  depends_on = [github_repository.repositories]
}
