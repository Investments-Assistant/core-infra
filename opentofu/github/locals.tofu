locals {
  repositories = {
    for name, repo in yamldecode(file("${path.module}/repositories.yaml")) :
    name => {
      name               = name
      description        = try(repo.description, null)
      gitignore_template = try(repo.gitignore_template, null)
      opentofu_state     = try(repo.opentofu_state, false)
      init_files = {
        code_of_conduct = try(var.repo_init_files[name].code_of_conduct == true, false)
        codeowners      = try(var.repo_init_files[name].codeowners == true, false)
        contributing    = try(var.repo_init_files[name].contributing == true, false)
        license         = try(var.repo_init_files[name].license == true, false)
        readme          = try(var.repo_init_files[name].readme == true, false)
      }
    }
  }
}

# ── Environments ───────────────────────────────────────────────────────────────

locals {
  app_repo     = "investments-assistant-raspberry-pi-5"
  environments = toset(["dev", "prod"])

  repo_secrets_flat = {
    for secret_name in nonsensitive(keys(var.repo_secrets)) :
    secret_name => {
      name  = secret_name
      value = var.repo_secrets[secret_name]
    }
  }

  repo_variables_flat = {
    for variable_name, variable_value in var.repo_variables :
    variable_name => {
      name  = variable_name
      value = variable_value
    }
  }
}
