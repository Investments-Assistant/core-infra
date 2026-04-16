resource "github_organization_settings" "github_organization_settings" {
  billing_email = var.github_organization_email
  email         = var.github_organization_email
  name          = var.github_organization_name
  description   = var.github_organization_description
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_membership" "owners" {
  for_each = var.org_owners
  username = each.value
  role     = "admin"

  lifecycle {
    prevent_destroy = true
  }
}
