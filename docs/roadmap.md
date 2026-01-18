# Roadmap

## Milestone 1: Admin node baseline

- Bootstrap script for Ubuntu 24.04+.
- Operator menu with Catppuccin theming.
- Questionnaire persistence and logging.
- Proxmox API token bootstrap (guarded and repeatable).
- Terraform and Ansible wrappers and placeholder playbooks.

## Milestone 2: Proxmox IaC

- Terraform modules for:
  - LXC creation (network, storage, DNS, tags)
  - VM creation (cloud-init for Ubuntu/Debian)
  - Template and ISO management
- Environment promotion: dev to prod patterns.

## Milestone 3: Core services

- DHCP server (implementation depends on your choice: Kea, ISC DHCP, or router-based leases).
- DNS server (Unbound, BIND, or AdGuard Home).
- Active Directory (Samba AD or Windows Server).

## Milestone 4: Platform engineering

- Talos Kubernetes (Proxmox-backed) with GitOps.
- UDMS integration.

## Emerging opportunities and risks

- Opportunity: treat Proxmox as an internal cloud and implement drift detection with regular Terraform plan checks.
- Risk: secrets sprawl. Use SOPS for in-repo secrets and Vaultwarden for operational secrets.
- Opportunity: standardise OS images with Packer to reduce configuration drift and speed up rebuilds.
