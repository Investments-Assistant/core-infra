module "github_environments" {
  source = "git::https://github.com/Investments-Assistant/opentofu-modules.git//github/environments?ref=main"

  providers = {
    github = github
  }

  app_repository                   = local.app_repository
  team_id                          = module.github_team.team_id
  environments                     = local.environments
  protected_environment            = "prod"
  protected_environment_wait_timer = 5
  repo_secrets                     = var.repo_secrets
  repo_variables                   = var.repo_variables
  manage_environments              = true
  manage_dev_deployment_policy     = true
  manage_actions_secrets           = true
  manage_actions_variables         = true

  depends_on = [module.github_repositories]
}
