variable "tf_state_buckets_names" {
  description = "The name of the S3 buckets to store OpenTofu states."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region for the S3 state bucket."
  type        = string
  default     = "eu-south-2"
}
