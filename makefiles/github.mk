# GitHub OpenTofu stack lifecycle.

.PHONY: github-init github-plan github-apply github-destroy \
        github-fmt github-fmt-check github-validate github-lint

github-init: ## Initialise the GitHub stack
	$(TOFU) -chdir=$(GH_DIR) init -reconfigure -upgrade
	$(TOFU) -chdir=$(GH_DIR) workspace select -or-create $(TT_ENV)

github-validate: github-init ## Validate the GitHub stack
	$(TOFU) -chdir=$(GH_DIR) validate -var-file=$(TT_ENV).ttvars

github-plan: github-validate ## Show pending changes for the GitHub stack
	$(TOFU) -chdir=$(GH_DIR) plan -var-file=$(TT_ENV).ttvars -out=ttplan -json-into=ttplan.json

github-apply: github-plan ## Apply the GitHub stack
	$(TOFU) -chdir=$(GH_DIR) apply -auto-approve -json-into=ttoutputs.json ttplan

github-destroy: github-init ## DANGER: Destroy all GitHub-managed resources
	$(TOFU) -chdir=$(GH_DIR) destroy -auto-approve -var-file=$(TT_ENV).ttvars

github-fmt: ## Auto-format the GitHub OpenTofu stack in place
	$(TOFU) -chdir=$(GH_DIR) fmt -recursive

github-fmt-check: ## Check GitHub OpenTofu formatting without modifying files
	$(TOFU) -chdir=$(GH_DIR) fmt -recursive -check

github-lint: ## Run tflint on the GitHub OpenTofu stack
	tflint --chdir=$(GH_DIR)
