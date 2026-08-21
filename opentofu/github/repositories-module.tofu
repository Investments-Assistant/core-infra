module "github_repositories" {
  source = "git::https://github.com/Investments-Assistant/opentofu-modules.git//github/repositories?ref=main"

  providers = {
    github = github
  }

  repositories                = local.repositories
  org_owners                  = var.org_owners
  repo_init_files             = var.repo_init_files
  repository_file_templates   = local.repository_file_templates
  manage_repositories         = true
  manage_vulnerability_alerts = true
  enable_security_features    = true
  manage_repository_files     = true
}
