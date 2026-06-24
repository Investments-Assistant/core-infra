terraform {
  required_version = ">= 1.10.0"
  backend "s3" {
    bucket       = "invass-core-infra-tt-state"
    key          = "github/invass-core-infra.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
    encrypt      = true
  }
}
