variable "tf_state_buckets_names" {
  description = "The name of the S3 buckets to store OpenTofu states."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region used by IAM policy ARNs."
  type        = string
  default     = "eu-south-2"
}

variable "github_actions_owner" {
  description = "GitHub organization or user that owns the Actions repository."
  type        = string
  default     = "Investments-Assistant"
}

variable "github_actions_repository" {
  description = "GitHub repository allowed to assume the Actions roles."
  type        = string
  default     = "investments-assistant-k8s"
}

variable "github_actions_allowed_branches" {
  description = "Repository branches allowed to assume the Actions roles."
  type        = list(string)
  default     = ["main"]
}

variable "github_actions_extra_subjects" {
  description = "Additional GitHub OIDC subject patterns allowed to assume the Actions roles."
  type        = list(string)
  default     = []
}

variable "github_actions_oidc_thumbprints" {
  description = "Thumbprints trusted for the GitHub Actions OIDC provider."
  type        = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1b511abead59c6ce207077c0bf0e0043b1382612",
  ]
}

variable "github_actions_ecr_repository_names" {
  description = "ECR repositories the build role may push to."
  type        = list(string)
  default = [
    "investments-gateway",
    "investments-market-data",
    "investments-news",
    "investments-portfolio",
    "investments-simulation",
    "investments-scheduler",
    "investments-forex",
  ]
}

variable "github_actions_terraform_state_bucket_names" {
  description = "S3 buckets containing the investments-assistant-k8s OpenTofu state."
  type        = list(string)
  default     = ["invass-investments-assistant-k8s-terraform-state-20260508003100"]
}

variable "github_actions_k8s_state_key" {
  description = "S3 key for the investments-assistant-k8s OpenTofu state file."
  type        = string
  default     = "investments-k8s/terraform.tfstate"
}

variable "github_actions_eks_cluster_name" {
  description = "EKS cluster name the deploy role may describe."
  type        = string
  default     = "investments-assistant"
}

variable "github_actions_tags" {
  description = "Additional tags applied to GitHub Actions IAM roles."
  type        = map(string)
  default     = {}
}
