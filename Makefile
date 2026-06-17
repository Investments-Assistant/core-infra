# ─────────────────────────────────────────────────────────────────────────────
# Core Infrastructure — Makefile
#
# Wraps the two OpenTofu stacks (aws, github) with a consistent interface.
#
# Prerequisites: tofu, tflint, pre-commit, poetry
#
# Quick start:
#   make install         # install local dev tooling (pre-commit)
#   make init            # tofu init on both stacks
#   make plan            # show pending changes (no writes)
#   make apply           # apply saved plans with auto-approve
#   make help            # full target list
#
# Variables (override on the command line):
#   AWS_PROFILE   – AWS credential profile used for S3 state backend
#                   default: investments-assistant-admin
#   TF_ENV        – OpenTofu workspace and tfvars prefix
#                   default: prod
# ─────────────────────────────────────────────────────────────────────────────

AWS_PROFILE  ?= investments-assistant-admin
TF_ENV       ?= prod
TOFU         ?= tofu
AWS_DIR      := terraform/aws
GH_DIR       := terraform/github

export AWS_PROFILE

.DEFAULT_GOAL := help

.PHONY: help install \
        init aws-init github-init \
        plan aws-plan github-plan \
        apply aws-apply github-apply \
        destroy aws-destroy github-destroy \
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
	@printf "  \033[33m%-20s\033[0m %s\n" "TF_ENV"       "$(TF_ENV)"
	@printf "  \033[33m%-20s\033[0m %s\n" "TOFU"         "$(TOFU)"

# ── Dev tooling ───────────────────────────────────────────────────────────────

install: ## Install local dev tools (pre-commit hooks)
	poetry install --no-root
	pre-commit install

# ── Init ─────────────────────────────────────────────────────────────────────

init: aws-init github-init ## Initialise all OpenTofu stacks

aws-init: ## Initialise the AWS stack
	$(TOFU) -chdir=$(AWS_DIR) init -reconfigure -upgrade
	$(TOFU) -chdir=$(AWS_DIR) workspace select -or-create $(TF_ENV)

github-init: ## Initialise the GitHub stack
	$(TOFU) -chdir=$(GH_DIR) init -reconfigure -upgrade
	$(TOFU) -chdir=$(GH_DIR) workspace select -or-create $(TF_ENV)

# ── Plan ─────────────────────────────────────────────────────────────────────

plan: aws-plan github-plan ## Create saved plans for all modules

aws-plan: aws-validate ## Show pending changes for the AWS module
	$(TOFU) -chdir=$(AWS_DIR) plan -var-file=$(TF_ENV).tfvars -out=ttplan -json-into=ttplan.json

github-plan: github-validate ## Show pending changes for the GitHub module
	$(TOFU) -chdir=$(GH_DIR) plan -var-file=$(TF_ENV).tfvars -out=ttplan -json-into=ttplan.json

# ── Apply ─────────────────────────────────────────────────────────────────────

apply: aws-apply github-apply ## Apply all modules

aws-apply: aws-plan ## Apply the AWS module
	$(TOFU) -chdir=$(AWS_DIR) apply -auto-approve -json-into=ttoutputs.json ttplan

github-apply: github-plan ## Apply the GitHub module
	$(TOFU) -chdir=$(GH_DIR) apply -auto-approve -json-into=ttoutputs.json ttplan

# ── Destroy ───────────────────────────────────────────────────────────────────

destroy: aws-destroy github-destroy ## DANGER: Destroy all managed resources

aws-destroy: aws-init ## DANGER: Destroy all AWS-managed resources
	$(TOFU) -chdir=$(AWS_DIR) destroy -auto-approve -var-file=$(TF_ENV).tfvars

github-destroy: github-init ## DANGER: Destroy all GitHub-managed resources
	$(TOFU) -chdir=$(GH_DIR) destroy -auto-approve -var-file=$(TF_ENV).tfvars

# ── Format ────────────────────────────────────────────────────────────────────

fmt: ## Auto-format all OpenTofu code in place
	$(TOFU) -chdir=$(AWS_DIR) fmt -recursive
	$(TOFU) -chdir=$(GH_DIR) fmt -recursive

fmt-check: ## Check formatting without modifying files (use in CI)
	$(TOFU) -chdir=$(AWS_DIR) fmt -recursive -check
	$(TOFU) -chdir=$(GH_DIR) fmt -recursive -check

# ── Validate ──────────────────────────────────────────────────────────────────

validate: aws-validate github-validate ## Validate all OpenTofu configurations

aws-validate: aws-init ## Validate the AWS module
	$(TOFU) -chdir=$(AWS_DIR) validate -var-file=$(TF_ENV).tfvars

github-validate: github-init ## Validate the GitHub module
	$(TOFU) -chdir=$(GH_DIR) validate -var-file=$(TF_ENV).tfvars

# ── Lint ──────────────────────────────────────────────────────────────────────

lint: aws-lint github-lint ## Run tflint on all modules

aws-lint: ## Run tflint on the AWS module
	tflint --chdir=$(AWS_DIR)

github-lint: ## Run tflint on the GitHub module
	tflint --chdir=$(GH_DIR)

# ── Pre-commit ────────────────────────────────────────────────────────────────

pre-commit: ## Run all pre-commit hooks against every tracked file
	pre-commit run --all-files
