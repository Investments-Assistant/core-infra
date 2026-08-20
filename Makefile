# ─────────────────────────────────────────────────────────────────────────────
# Core Infrastructure — Makefile
#
# The root file owns shared configuration and repository-wide aliases. Stack
# lifecycles and developer tooling live in makefiles/ so each concern can grow
# independently without turning this file into a second orchestration script.
# ─────────────────────────────────────────────────────────────────────────────

ROOT_DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TT_ENV       ?= prod
TOFU         ?= tofu
GH_DIR       := $(ROOT_DIR)opentofu/github
.DEFAULT_GOAL := help

include $(ROOT_DIR)makefiles/github.mk
include $(ROOT_DIR)makefiles/tooling.mk

.PHONY: help \
        init plan apply destroy \
        fmt fmt-check validate lint

# ── Help ─────────────────────────────────────────────────────────────────────

help: ## Show this help
	@printf "Usage: make <target>\n\n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf "\nVariables (override with make <target> VAR=value):\n"
	@printf "  \033[33m%-20s\033[0m %s\n" "TT_ENV" "$(TT_ENV)"
	@printf "  \033[33m%-20s\033[0m %s\n" "TOFU" "$(TOFU)"

# ── Stack-wide aliases ──────────────────────────────────────────────────────

init: github-init ## Initialise all OpenTofu stacks

plan: github-plan ## Create saved plans for all stacks

apply: github-apply ## Apply all stacks

destroy: github-destroy ## DANGER: Destroy all managed resources

fmt: github-fmt ## Auto-format all OpenTofu code in place

fmt-check: github-fmt-check ## Check OpenTofu formatting without modifying files

validate: github-validate ## Validate all OpenTofu configurations

lint: github-lint ## Run tflint on all OpenTofu modules
