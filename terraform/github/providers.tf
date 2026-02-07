terraform {
  required_version = ">= 1.13.4"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  owner = "Investments-Assistant"
}
