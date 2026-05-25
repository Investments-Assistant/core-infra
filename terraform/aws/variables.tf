variable "tf_state_buckets_names" {
  description = "The name of the S3 buckets to store Terraform states."
  type        = list(string)
}
