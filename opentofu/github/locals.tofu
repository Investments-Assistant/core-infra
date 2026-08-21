locals {
  repositories   = yamldecode(file("${path.module}/repositories.yaml"))
  app_repository = "investments-assistant-raspberry-pi-5"
  environments   = toset(["dev", "prod"])

  repository_file_templates = {
    code_of_conduct = file("${path.module}/files_templates/CODE_OF_CONDUCT_template")
    codeowners      = file("${path.module}/files_templates/CODEOWNERS_template")
    contributing    = file("${path.module}/files_templates/CONTRIBUTING_template")
    license         = file("${path.module}/files_templates/LICENSE_template")
    readme          = file("${path.module}/files_templates/README_template")
  }
}
