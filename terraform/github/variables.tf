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

# ── Environment secrets & variables ───────────────────────────────────────────

variable "dev_secrets" {
  description = "Secrets injected into the dev GitHub Actions environment (sensitive — use terraform.tfvars)"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "dev_variables" {
  description = "Non-sensitive variables injected into the dev GitHub Actions environment"
  type        = map(string)
  default     = {}
}

variable "prod_secrets" {
  description = "Secrets injected into the prod GitHub Actions environment (sensitive — use terraform.tfvars)"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "prod_variables" {
  description = "Non-sensitive variables injected into the prod GitHub Actions environment"
  type        = map(string)
  default     = {}
}

# ── Repository-level secrets (available to all workflows, not env-scoped) ─────

variable "repo_secrets" {
  description = "Repository-level Actions secrets shared across all environments (e.g. SONAR_TOKEN)"
  type        = map(string)
  sensitive   = true
  default     = {}
}
