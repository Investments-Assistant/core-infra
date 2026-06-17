data "aws_caller_identity" "current" {}

locals {
  github_actions_oidc_url = "token.actions.githubusercontent.com"
  ecr_repository_arns = [
    for repository_name in var.github_actions_ecr_repository_names :
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${repository_name}"
  ]
  terraform_state_object_arns = flatten([
    for bucket_name in var.github_actions_terraform_state_bucket_names : [
      "arn:aws:s3:::${bucket_name}/${var.github_actions_k8s_state_key}",
      "arn:aws:s3:::${bucket_name}/env:/*/${var.github_actions_k8s_state_key}",
      "arn:aws:s3:::${bucket_name}/${var.github_actions_k8s_state_key}.tflock",
      "arn:aws:s3:::${bucket_name}/env:/*/${var.github_actions_k8s_state_key}.tflock",
    ]
  ])
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://${local.github_actions_oidc_url}"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_actions_oidc_thumbprints

  tags = {
    Name = "github-actions"
  }
}

data "aws_iam_policy_document" "github_actions_build" {
  statement {
    sid       = "EcrLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushInvestmentAssistantImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = local.ecr_repository_arns
  }
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "ReadK8sOpenTofuState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = local.terraform_state_object_arns
  }

  statement {
    sid       = "ListK8sOpenTofuState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [for bucket_name in var.github_actions_terraform_state_bucket_names : "arn:aws:s3:::${bucket_name}"]
  }

  statement {
    sid     = "DescribeEksCluster"
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.github_actions_eks_cluster_name}",
    ]
  }

  statement {
    sid    = "ReadLoadBalancerForDnsAlias"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageApplicationDnsAlias"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:ListHostedZonesByName",
    ]
    resources = ["*"]
  }
}

module "github_actions_build_role" {
  source = "git::ssh://git@github.com/Investments-Assistant/terraform-modules.git//github_actions_oidc_role?ref=v1.3.0"

  role_name         = "investments-assistant-github-actions-build-role"
  oidc_provider_arn = aws_iam_openid_connect_provider.github_actions.arn
  oidc_provider_url = local.github_actions_oidc_url
  github_owner      = var.github_actions_owner
  github_repository = var.github_actions_repository
  allowed_branches  = var.github_actions_allowed_branches
  extra_subjects    = var.github_actions_extra_subjects
  policy_json       = data.aws_iam_policy_document.github_actions_build.json
  tags              = var.github_actions_tags
}

module "github_actions_deploy_role" {
  source = "git::ssh://git@github.com/Investments-Assistant/terraform-modules.git//github_actions_oidc_role?ref=v1.3.0"

  role_name         = "investments-assistant-github-actions-deploy-role"
  oidc_provider_arn = aws_iam_openid_connect_provider.github_actions.arn
  oidc_provider_url = local.github_actions_oidc_url
  github_owner      = var.github_actions_owner
  github_repository = var.github_actions_repository
  allowed_branches  = var.github_actions_allowed_branches
  extra_subjects    = var.github_actions_extra_subjects
  policy_json       = data.aws_iam_policy_document.github_actions_deploy.json
  tags              = var.github_actions_tags
}
