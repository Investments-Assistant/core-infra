data "terraform_remote_state" "aws" {
  backend = "s3"

  config = {
    bucket = local.aws_backend_bucket
    key    = local.aws_state_key
  }
}
