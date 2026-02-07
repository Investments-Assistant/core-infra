locals {
  repositories = {
    for name, repo in yamldecode(file("${path.module}/repositories.yaml")) :
    name => {
      name              = name
      description       = try(repo.description, null)
      gitignore_template = try(repo.gitignore_template, null)
      terraform_state   = try(repo.terraform_state, false)
    }
  }
}
