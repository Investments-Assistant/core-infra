# AWS Core Infrastructure

This stack owns account-level AWS resources used across the Investments
Assistant repositories:

- S3 buckets for OpenTofu state.
- GitHub Actions OIDC provider for `token.actions.githubusercontent.com`.
- GitHub Actions IAM roles for the `investments-assistant-k8s` workflows.

## GitHub Actions OIDC Roles

Created roles:

- `investments-assistant-github-actions-build-role`
- `investments-assistant-github-actions-deploy-role`

The trust policy is scoped to `Investments-Assistant/investments-assistant-k8s`
on the configured branches, defaulting to `main`.

After applying this stack, apply `terraform/github`. The GitHub stack creates
empty repository variables named `AWS_BUILD_ROLE_ARN` and
`AWS_DEPLOY_ROLE_ARN` for the workflow repositories. Fill those variables in
GitHub with the matching AWS stack outputs, `github_actions_build_role_arn` and
`github_actions_deploy_role_arn`.
