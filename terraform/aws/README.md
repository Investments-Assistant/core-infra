# AWS Core Infrastructure

This stack owns account-level AWS resources used across the Investments
Assistant repositories:

- S3 buckets for OpenTofu state.

The application itself does not run in AWS. This stack exists only so
`terraform/github` and `terraform/aws` can share a durable, private, locked S3
backend.
