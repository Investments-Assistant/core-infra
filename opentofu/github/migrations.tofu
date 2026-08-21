# Preserve the existing root state addresses while resources move into the
# granular reusable modules.

moved {
  from = github_organization_settings.github_organization_settings
  to   = module.github_organization.github_organization_settings.github_organization_settings[0]
}

moved {
  from = github_membership.owners["lupirex"]
  to   = module.github_organization.github_membership.owners["lupirex"]
}

moved {
  from = github_repository.repositories["core-infra"]
  to   = module.github_repositories.github_repository.repositories["core-infra"]
}

moved {
  from = github_repository.repositories["investments-assistant-local-machine"]
  to   = module.github_repositories.github_repository.repositories["investments-assistant-local-machine"]
}

moved {
  from = github_repository.repositories["investments-assistant-raspberry-pi-5"]
  to   = module.github_repositories.github_repository.repositories["investments-assistant-raspberry-pi-5"]
}

moved {
  from = github_repository.repositories["opentofu-modules"]
  to   = module.github_repositories.github_repository.repositories["opentofu-modules"]
}

moved {
  from = github_repository_vulnerability_alerts.repositories["core-infra"]
  to   = module.github_repositories.github_repository_vulnerability_alerts.repositories["core-infra"]
}

moved {
  from = github_repository_vulnerability_alerts.repositories["investments-assistant-local-machine"]
  to   = module.github_repositories.github_repository_vulnerability_alerts.repositories["investments-assistant-local-machine"]
}

moved {
  from = github_repository_vulnerability_alerts.repositories["investments-assistant-raspberry-pi-5"]
  to   = module.github_repositories.github_repository_vulnerability_alerts.repositories["investments-assistant-raspberry-pi-5"]
}

moved {
  from = github_repository_vulnerability_alerts.repositories["opentofu-modules"]
  to   = module.github_repositories.github_repository_vulnerability_alerts.repositories["opentofu-modules"]
}

moved {
  from = github_team.core
  to   = module.github_team.github_team.core[0]
}

moved {
  from = github_team_membership.core_owners["lupirex"]
  to   = module.github_team.github_team_membership.core_owners["lupirex"]
}

moved {
  from = github_repository_environment.app_envs["dev"]
  to   = module.github_environments.github_repository_environment.app_envs["dev"]
}

moved {
  from = github_repository_environment.app_envs["prod"]
  to   = module.github_environments.github_repository_environment.app_envs["prod"]
}

moved {
  from = github_repository_environment_deployment_policy.dev_any_branch
  to   = module.github_environments.github_repository_environment_deployment_policy.dev_any_branch[0]
}

moved {
  from = github_actions_secret.repo_secrets["SONAR_TOKEN"]
  to   = module.github_environments.github_actions_secret.repo_secrets["SONAR_TOKEN"]
}

moved {
  from = github_actions_variable.repo_variables["PI_DEPLOY_DIR"]
  to   = module.github_environments.github_actions_variable.repo_variables["PI_DEPLOY_DIR"]
}
