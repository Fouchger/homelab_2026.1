# homelab_2026.1

A modular, repeatable Proxmox homelab platform that bootstraps an admin node and then uses Terraform, Packer, and Ansible to create, configure, and keep your environment up to date.

## Quick start

Recommended: run this from a dedicated Ubuntu 24.04+ admin VM/LXC.

1. Install git.

   sudo apt-get update && sudo apt-get install -y git make

2. Clone the repo.

    git clone -b main "https://github.com/Fouchger/homelab_2026.1" "$HOME/Fouchger/homelab_2026.1"
    cd "$HOME/Fouchger/homelab_2026.1"

3. Bootstrap dependencies and open the menu.

   make bootstrap
   make menu

## What you get in this baseline

- A professional terminal menu with spacebar selection using `dialog`.
- Catppuccin colour themes (all flavours) and emoji toggles.
- Logging to both screen and a per-run log file.
- Questionnaires to capture and persist key settings (safe to re-run).
- Scaffolding for:
  - Proxmox API token bootstrap
  - Template download and management
  - VM/LXC create/destroy workflows (Terraform)
  - Service deployments (Ansible roles)
  - Image build pipeline (Packer)
  - Secrets discipline (SOPS + Vaultwarden pattern)

## Key entry points

- `scripts/bootstrap.sh`: installs basic requirements and wires up this repo.
- `scripts/menu.sh`: interactive menu (works on systems with and without a GUI).
- `generated_configs/`: generated runtime config files (gitignored).

## Documentation

- `docs/standards.md`: development standards (markdownlint, prettier, pre-commit).
- `docs/architecture.md`: how the modules fit together.
- `docs/questionnaires.md`: what we ask and why.
- `docs/roadmap.md`: next milestones and design decisions.

## Security notes

- Do not commit secrets. This repo is set up to ignore generated configs, `.env` files, SOPS decrypted artefacts, Terraform state, and Vaultwarden data.
- Use SOPS to store encrypted secrets in-repo, and use Vaultwarden as an operational store for credentials.

