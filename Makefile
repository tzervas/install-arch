# Makefile for install-arch development
# Provides common development tasks and Dev Container management

.PHONY: help build rebuild clean update status test lint format ci install dev-setup

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

# Dev Container management
build: ## Build the Dev Container image
	./scripts/devcontainer.sh build

rebuild: ## Rebuild the Dev Container image (no cache)
	./scripts/devcontainer.sh rebuild

clean: ## Clean up unused containers, images, and volumes
	./scripts/devcontainer.sh clean

update: ## Update dependencies inside the running container
	./scripts/devcontainer.sh update

status: ## Show Dev Container status
	./scripts/devcontainer.sh status

automate: ## Run complete Dev Container automation sequence
	./scripts/run-devcontainer-automation.sh

# Development tasks
install: ## Install the package in development mode
	uv pip install -e .

dev-setup: ## Set up development environment
	uv sync
	uv pip install -e .
	pre-commit install

test: ## Run tests with coverage
	uv run pytest tests/ --cov=src/install_arch --cov-report=term-missing

lint: ## Run linting checks
	uv run ruff check src/ tests/
	uv run mypy src/install_arch/

format: ## Format code
	uv run ruff format src/ tests/
	uv run ruff check --fix src/ tests/

ci: ## Run local CI checks
	./scripts/run-local-ci.sh

# Combined targets
check: lint test ## Run linting and tests
fix: format ## Fix formatting issues

# Guardrails
guardrails: ## Check guardrails compliance
	uv run python -m install_arch.cli check-guardrails

enforce-guardrails: ## Enforce guardrails compliance
	uv run python -m install_arch.cli enforce-guardrails

# Validation scripts
validate-all: ## Run all validation scripts
	./scripts/run-full-validation.sh

validate-security: ## Run security validation
	./scripts/validate-security.sh

validate-hardware: ## Run hardware validation
	./scripts/validate-hardware.sh

validate-packages: ## Run package installation validation
	./scripts/validate-package-installation.sh

validate-services: ## Run service validation
	./scripts/validate-services.sh

validate-applications: ## Run application validation
	./scripts/validate-applications.sh

validate-kde: ## Run KDE desktop validation
	./scripts/validate-kde-desktop.sh