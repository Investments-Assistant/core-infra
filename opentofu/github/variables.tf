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

# ── Repository-level secrets (available to all workflows, not env-scoped) ─────

variable "repo_secrets" {
  description = "Repository-level Actions secrets shared across all environments (e.g. SONAR_TOKEN)"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "repo_variables" {
  description = "Repository-level Actions variables shared across investments-assistant workflows."
  type        = map(string)
  default     = {}
}

# ── Repository boilerplate files ──────────────────────────────────────────────

variable "repo_init_files" {
  description = "Per-repository flags controlling which boilerplate files OpenTofu manages."
  type = map(object({
    code_of_conduct = optional(bool)
    codeowners      = optional(bool)
    contributing    = optional(bool)
    license         = optional(bool)
    readme          = optional(bool)
  }))
  default = {}
}
