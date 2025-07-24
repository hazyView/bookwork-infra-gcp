.PHONY: help setup init plan apply destroy clean validate fmt docs

# Default target
help: ## Show this help message
	@echo "Bookwork GCP Infrastructure Makefile"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Set up terraform.tfvars from example
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "✓ Created terraform.tfvars from example"; \
		echo "⚠ Please edit terraform.tfvars with your project details"; \
	else \
		echo "✓ terraform.tfvars already exists"; \
	fi

init: ## Initialize Terraform
	terraform init

validate: ## Validate Terraform configuration
	terraform validate

fmt: ## Format Terraform files
	terraform fmt -recursive

plan: ## Plan Terraform deployment
	terraform plan

apply: ## Apply Terraform configuration
	terraform apply

destroy: ## Destroy Terraform infrastructure
	terraform destroy

clean: ## Clean Terraform temporary files
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate.backup
	rm -f tfplan

docs: ## Generate documentation
	@echo "# Terraform Resources" > RESOURCES.md
	@echo "" >> RESOURCES.md
	@terraform providers schema -json | jq -r '.provider_schemas."registry.terraform.io/hashicorp/google".resource_schemas | keys[]' | sort | sed 's/^/- /' >> RESOURCES.md

# Development targets
dev-plan: fmt validate plan ## Format, validate, and plan (development workflow)

dev-apply: fmt validate apply ## Format, validate, and apply (development workflow)

# Check required environment
check-env:
	@if [ ! -f terraform.tfvars ]; then \
		echo "❌ terraform.tfvars not found. Run 'make setup' first."; \
		exit 1; \
	fi
	@if ! command -v terraform >/dev/null 2>&1; then \
		echo "❌ Terraform not found. Please install Terraform."; \
		exit 1; \
	fi
	@if ! command -v gcloud >/dev/null 2>&1; then \
		echo "❌ gcloud not found. Please install Google Cloud CLI."; \
		exit 1; \
	fi
