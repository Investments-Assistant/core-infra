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

# ── Environments ───────────────────────────────────────────────────────────────

locals {
  app_repo = "investments-assistant"

  environments = {
    dev = {
      variables = merge(
        {
          ENVIRONMENT            = "development"
          TRADING_MODE           = "recommend"
          APP_HOST               = "0.0.0.0"
          APP_PORT               = "8000"
          LLM_BACKEND            = "llama_cpp"
          NEWSLETTER_IMAP_SERVER = "imap.gmail.com"
          NEWSLETTER_IMAP_PORT   = "993"
        },
        var.dev_variables
      )
      secrets = var.dev_secrets
    }

    prod = {
      variables = merge(
        {
          ENVIRONMENT            = "production"
          TRADING_MODE           = "auto"
          APP_HOST               = "0.0.0.0"
          APP_PORT               = "8000"
          LLM_BACKEND            = "llama_cpp"
          NEWSLETTER_IMAP_SERVER = "imap.gmail.com"
          NEWSLETTER_IMAP_PORT   = "993"
        },
        var.prod_variables
      )
      secrets = var.prod_secrets
    }
  }

  # Flatten {env -> {name -> value}} into a unique keyed map for for_each
  env_secrets_flat = merge([
    for env_name, env_cfg in local.environments : {
      for secret_name, secret_value in env_cfg.secrets :
      "${env_name}__${secret_name}" => {
        environment = env_name
        name        = secret_name
        value       = secret_value
      }
    }
  ]...)

  env_variables_flat = merge([
    for env_name, env_cfg in local.environments : {
      for var_name, var_value in env_cfg.variables :
      "${env_name}__${var_name}" => {
        environment = env_name
        name        = var_name
        value       = var_value
      }
    }
  ]...)

  repo_secrets_flat = {
    for secret_name, secret_value in var.repo_secrets :
    secret_name => {
      name  = secret_name
      value = secret_value
    }
  }
}
