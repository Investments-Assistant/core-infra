output "github_actions_build_role_arn" {
  description = "IAM role ARN for GitHub Actions image builds."
  value       = module.github_actions_build_role.role_arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions EKS deployments."
  value       = module.github_actions_deploy_role.role_arn
}
