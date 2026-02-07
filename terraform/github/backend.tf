terraform {
  required_version = ">= 1.13.4"
  backend "s3" {
    bucket       = "invass-core-infra-terraform-state-20251026205837245600000001"
    key          = "github/invass-core-infra.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
    encrypt      = true
  }
}
