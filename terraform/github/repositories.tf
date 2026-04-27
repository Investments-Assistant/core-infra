resource "github_repository" "repositories" {
  for_each               = local.repositories
  name                   = each.value.name
  description            = each.value.description
  gitignore_template     = each.value.gitignore_template
  has_issues             = true
  has_discussions        = true
  has_wiki               = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  delete_branch_on_merge = true
  allow_update_branch    = true
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "repositories" {
  for_each   = local.repositories
  repository = each.value.name
  enabled    = true

  depends_on = [github_repository.repositories]
}

resource "github_repository_file" "code_of_conduct" {
  for_each = {
    for name, repo in github_repository.repositories :
    name => repo if local.repositories[name].init_files.code_of_conduct
  }
  repository          = each.value.name
  file                = "CODE_OF_CONDUCT"
  content             = file("${path.module}/files_templates/CODE_OF_CONDUCT_template")
  overwrite_on_create = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_file" "codeowners" {
  for_each = {
    for name, repo in github_repository.repositories :
    name => repo if local.repositories[name].init_files.codeowners
  }
  repository          = each.value.name
  file                = "CODEOWNERS"
  content             = templatefile("${path.module}/files_templates/CODEOWNERS_template", {
    codeowners = join(", ", var.org_owners)
  })
  overwrite_on_create = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_file" "contributing" {
  for_each = {
    for name, repo in github_repository.repositories :
    name => repo if local.repositories[name].init_files.contributing
  }
  repository          = each.value.name
  file                = "CONTRIBUTING"
  content             = file("${path.module}/files_templates/CONTRIBUTING_template")
  overwrite_on_create = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_file" "license" {
  for_each = {
    for name, repo in github_repository.repositories :
    name => repo if local.repositories[name].init_files.license
  }
  repository          = each.value.name
  file                = "LICENSE"
  content             = file("${path.module}/files_templates/LICENSE_template")
  overwrite_on_create = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_file" "readme" {
  for_each = {
    for name, repo in github_repository.repositories :
    name => repo if local.repositories[name].init_files.readme
  }
  repository          = each.value.name
  file                = "README.md"
  content             = templatefile("${path.module}/files_templates/README_template", {
    repository_name = each.value.name
    description     = local.repositories[each.value.name].description
  })
  overwrite_on_create = true
  lifecycle {
    prevent_destroy = true
  }
}
