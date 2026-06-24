resource "github_team" "core" {
  name        = "core"
  description = "Core maintainers"
  privacy     = "closed"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_membership" "core_owners" {
  for_each = var.org_owners
  team_id  = github_team.core.id
  username = each.value
  role     = "maintainer"
  lifecycle {
    prevent_destroy = true
  }
}
