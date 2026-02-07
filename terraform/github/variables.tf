variable "github_organization_email" {
  description = "Billing email for the GitHub organization"
  type        = string
}

variable "github_organization_name" {
  description = "Name of the GitHub organization"
  type        = string
}

variable "github_organization_description" {
  description = "Description of the GitHub organization"
  type        = string
}

variable "org_owners" {
  type = set(string)
}
