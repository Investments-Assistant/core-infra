terraform {
  required_version = "1.12.6"
  backend "local" {
    path = "backend/opentofu.ttstate"
  }
}
