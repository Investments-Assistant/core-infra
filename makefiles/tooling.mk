# Repository-wide development tooling.

.PHONY: install pre-commit

install: ## Install local development tools and pre-commit hooks
	poetry install --no-root
	pre-commit install

pre-commit: ## Run all pre-commit hooks against every tracked file
	pre-commit run --all-files
