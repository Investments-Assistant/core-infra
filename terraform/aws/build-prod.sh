#!/bin/bash

export AWS_PROFILE="investments-assistant-admin"

echo "Initializing Terraform..."
terraform init -reconfigure -upgrade

echo "Selecting production workspace..."
terraform workspace select --or-create prod

echo "Applying Terraform configuration for production..."
terraform apply -auto-approve -var-file="prod.tfvars"

echo "Terraform apply completed."
