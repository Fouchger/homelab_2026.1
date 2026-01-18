# Development standards

This repo aims to be easy to maintain, safe-by-default, and consistent across contributors.

## Repo conventions

- Default shell: `bash`.
- Default OS target: Ubuntu 24.04+ (admin node). Proxmox nodes are managed remotely via API/SSH.
- Idempotency first: scripts must be safe to re-run.
- Modular design: avoid monolithic scripts. Add functionality as self-contained modules.
- No secrets in git: use SOPS for encrypted in-repo secrets and Vaultwarden for operational secrets.

## Bash standards

- `set -Eeuo pipefail` is mandatory.
- All scripts must include a header block describing purpose, usage, and maintainer notes.
- Use the shared library functions in `scripts/lib/` (logging, colours, prompts, files).
- Avoid `sudo` spread throughout scripts. Use `as_root` helper.

## Python standards

- Target Python 3.12+.
- Type hints for public functions.
- `ruff` and `black` are used for linting/formatting.

## Terraform standards

- One root module per environment under `terraform/environments/`.
- Reusable modules live under `terraform/modules/`.
- State management: local by default in this baseline, with documented upgrade path to remote backend.

## Ansible standards

- Roles are single-purpose, composable, and take their configuration via variables.
- Inventory lives under `ansible/inventory/`.

## Formatting and linting

This repo uses:

- `pre-commit` for running checks locally before each commit.
- `markdownlint-cli2` for Markdown.
- `prettier` for YAML/JSON/Markdown formatting.

### Pre-commit

Install and enable:

- `python3 -m pip install --user pre-commit`
- `pre-commit install`

Then run:

- `pre-commit run --all-files`

### Markdown linting

Rules are configured in `.markdownlint.yaml`.

### Prettier

Config is in `.prettierrc`.

