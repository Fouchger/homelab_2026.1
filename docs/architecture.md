# Architecture

## Intent

homelab_2026.1 is built around a simple separation of concerns:

- Bootstrap: minimal prerequisites to run the stack.
- Provision: create and destroy Proxmox resources (Terraform).
- Build: create reusable VM templates and images (Packer).
- Configure: install, configure, and maintain services (Ansible).
- Operators: a consistent menu and questionnaires so it is easy to run in a terminal-only environment.

This baseline does not attempt to implement every service end-to-end yet. It provides a production-grade scaffold with strong operational controls: idempotency, logging, safe config persistence, and clear module boundaries.

## Modules

### Bash orchestration

- `scripts/menu.sh`: main operator UI.
- `scripts/lib/`: shared libraries (logging, config, UI, Proxmox helpers).

### Terraform

- `terraform/environments/`: per-environment root modules.
- `terraform/modules/`: reusable modules (LXC, VM, networks, storage).

### Ansible

- `ansible/playbooks/`: thin playbooks that call roles.
- `ansible/roles/`: reusable roles for:
  - admin node
  - DHCP
  - DNS
  - Active Directory
  - Talos Kubernetes
  - UDMS
  - Vaultwarden

### Packer

- `packer/`: image builds (future expansion).

## Self-heal approach

The baseline provides the hooks for self-heal rather than pretending it can fully recover from all drift:

- Critical configuration is persisted under `generated_configs/`.
- If config files are missing, the menu routes you back through questionnaires.
- Terraform and Ansible are designed to be re-run.

