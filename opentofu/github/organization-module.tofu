module "github_organization" {
  # Pin this to a released opentofu-modules tag after the module repository
  # publishes the next release. `main` keeps the two local repositories aligned
  # during this extraction.
  source = "git::https://github.com/Investments-Assistant/opentofu-modules.git//github/organization?ref=main"

  providers = {
    github = github
  }

  github_organization_email       = var.github_organization_email
  github_organization_name        = var.github_organization_name
  github_organization_description = var.github_organization_description
  org_owners                      = var.org_owners
  manage_settings                 = true
  manage_memberships              = true
}
