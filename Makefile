# ─────────────────────────────────────────────────────────────────────────────
# Core Infrastructure — Makefile
#
# Wraps the two Terraform modules (aws, github) with a consistent interface.
#
# Prerequisites: terraform, tflint, pre-commit, poetry
#
# Quick start:
#   make install         # install local dev tooling (pre-commit)
#   make init            # terraform init on both modules
#   make plan            # show pending changes (no writes)
#   make apply           # apply changes (interactive confirmation required)
#   make help            # full target list
#
# Variables (override on the command line):
#   AWS_PROFILE   – AWS credential profile used for S3 state backend
#                   default: investments-assistant-admin
#   TF_WORKSPACE  – Terraform workspace to select before plan/apply/destroy
#                   default: prod
#   TFVARS        – var-file name (relative to each module directory)
#                   default: terraform.tfvars
# ─────────────────────────────────────────────────────────────────────────────

AWS_PROFILE  ?= investments-assistant-admin
TF_WORKSPACE ?= prod
AWS_DIR      := terraform/aws
GH_DIR       := terraform/github
TFVARS       := terraform.tfvars

export AWS_PROFILE

.DEFAULT_GOAL := help

.PHONY: help install \
        init aws-init github-init \
        plan aws-plan github-plan \
        apply aws-apply github-apply \
        aws-destroy github-destroy \
        fmt fmt-check \
        validate aws-validate github-validate \
        lint aws-lint github-lint \
        pre-commit

# ── Help ─────────────────────────────────────────────────────────────────────

help: ## Show this help
	@printf "Usage: make <target>\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf "\nVariables (override with make <target> VAR=value):\n"
	@printf "  \033[33m%-20s\033[0m %s\n" "AWS_PROFILE"  "$(AWS_PROFILE)"
	@printf "  \033[33m%-20s\033[0m %s\n" "TF_WORKSPACE" "$(TF_WORKSPACE)"
	@printf "  \033[33m%-20s\033[0m %s\n" "TFVARS"       "$(TFVARS)"

# ── Dev tooling ───────────────────────────────────────────────────────────────

install: ## Install local dev tools (pre-commit hooks)
	poetry install --no-root
	pre-commit install

# ── Init ─────────────────────────────────────────────────────────────────────

init: aws-init github-init ## Initialise all Terraform modules

aws-init: ## Initialise the AWS module (terraform init -upgrade)
	terraform -chdir=$(AWS_DIR) init -upgrade

github-init: ## Initialise the GitHub module (terraform init -upgrade)
	terraform -chdir=$(GH_DIR) init -upgrade

# ── Plan ─────────────────────────────────────────────────────────────────────

plan: aws-plan github-plan ## Show pending changes for all modules (no writes)

aws-plan: ## Show pending changes for the AWS module
	terraform -chdir=$(AWS_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(AWS_DIR) plan -var-file=$(TFVARS)

github-plan: ## Show pending changes for the GitHub module
	terraform -chdir=$(GH_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(GH_DIR) plan -var-file=$(TFVARS)

# ── Apply ─────────────────────────────────────────────────────────────────────

apply: aws-apply github-apply ## Apply all modules (interactive confirmation required)

aws-apply: ## Apply the AWS module (interactive confirmation required)
	terraform -chdir=$(AWS_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(AWS_DIR) apply -var-file=$(TFVARS)

github-apply: ## Apply the GitHub module (interactive confirmation required)
	terraform -chdir=$(GH_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(GH_DIR) apply -var-file=$(TFVARS)

# ── Destroy ───────────────────────────────────────────────────────────────────

aws-destroy: ## DANGER: Destroy all AWS-managed resources
	terraform -chdir=$(AWS_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(AWS_DIR) destroy -var-file=$(TFVARS)

github-destroy: ## DANGER: Destroy all GitHub-managed resources
	terraform -chdir=$(GH_DIR) workspace select -or-create $(TF_WORKSPACE)
	terraform -chdir=$(GH_DIR) destroy -var-file=$(TFVARS)

# ── Format ────────────────────────────────────────────────────────────────────

fmt: ## Auto-format all Terraform code in place
	terraform -chdir=$(AWS_DIR) fmt -recursive
	terraform -chdir=$(GH_DIR) fmt -recursive

fmt-check: ## Check formatting without modifying files (use in CI)
	terraform -chdir=$(AWS_DIR) fmt -recursive -check
	terraform -chdir=$(GH_DIR) fmt -recursive -check

# ── Validate ──────────────────────────────────────────────────────────────────

validate: aws-validate github-validate ## Validate all Terraform configurations (requires init first)

aws-validate: ## Validate the AWS module
	terraform -chdir=$(AWS_DIR) validate

github-validate: ## Validate the GitHub module
	terraform -chdir=$(GH_DIR) validate

# ── Lint ──────────────────────────────────────────────────────────────────────

lint: aws-lint github-lint ## Run tflint on all modules

aws-lint: ## Run tflint on the AWS module
	tflint --chdir=$(AWS_DIR)

github-lint: ## Run tflint on the GitHub module
	tflint --chdir=$(GH_DIR)

# ── Pre-commit ────────────────────────────────────────────────────────────────

pre-commit: ## Run all pre-commit hooks against every tracked file
	pre-commit run --all-files
