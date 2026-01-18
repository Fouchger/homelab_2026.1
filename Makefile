# =============================================================================
# homelab_2026.1 - Make targets
# =============================================================================
# Purpose
#   Human-friendly entry points for bootstrapping and operating the homelab.
# =============================================================================

SHELL := /bin/bash

.PHONY: help bootstrap menu questionnaire proxmox-token templates tf-init tf-plan tf-apply tf-destroy ansible-admin ansible-core lint

help:
	@echo "homelab_2026.1"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  bootstrap      Install minimal prerequisites on the admin node"
	@echo "  menu           Launch the interactive menu"
	@echo "  questionnaire  Run core questionnaire and persist config"
	@echo "  proxmox-token  Bootstrap Proxmox API token for automation"
	@echo "  templates      Download common LXC templates (best-effort)"
	@echo "  tf-init        Terraform init (ENV=dev|prod)"
	@echo "  tf-plan        Terraform plan (ENV=dev|prod)"
	@echo "  tf-apply       Terraform apply (ENV=dev|prod)"
	@echo "  tf-destroy     Terraform destroy (ENV=dev|prod)"
	@echo "  ansible-admin  Configure admin node via Ansible"
	@echo "  ansible-core   Deploy core services via Ansible (placeholders)"
	@echo "  lint           Run pre-commit checks (requires pre-commit)"

bootstrap:
	@./scripts/bootstrap.sh

menu:
	@./scripts/menu.sh

questionnaire:
	@HL_DEBUG=1 ./scripts/menu.sh </dev/tty

proxmox-token:
	@./scripts/proxmox/bootstrap-api-token.sh

templates:
	@./scripts/menu.sh </dev/tty

ENV ?= dev

tf-init:
	@cd terraform/environments/$(ENV) && terraform init

tf-plan:
	@cd terraform/environments/$(ENV) && terraform plan

tf-apply:
	@cd terraform/environments/$(ENV) && terraform apply

tf-destroy:
	@cd terraform/environments/$(ENV) && terraform destroy

ansible-admin:
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/admin_node.yml

ansible-core:
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/core_services.yml

lint:
	@pre-commit run --all-files
