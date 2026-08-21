module "github_team" {
  source = "git::https://github.com/Investments-Assistant/opentofu-modules.git//github/team?ref=main"

  providers = {
    github = github
  }

  team_name          = "core"
  team_description   = "Core maintainers"
  team_privacy       = "closed"
  members            = var.org_owners
  membership_role    = "maintainer"
  create_team        = true
  manage_memberships = true
}
