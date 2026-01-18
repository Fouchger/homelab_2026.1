#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Proxmox helpers
# =============================================================================
# Purpose
#   Convenience actions against Proxmox nodes via SSH and API token handover.
#
# Scope
#   - Template operations are implemented via SSH (pveam/pvesm) because it is dependable.
#   - VM/LXC lifecycle is intended to be handled by Terraform modules.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/config.sh"

proxmox_ssh_cmd() {
  config_load_exports
  local user="${PROXMOX_SSH_USER:-root}"
  local host="${PROXMOX_HOST:?PROXMOX_HOST not set}"
  local port="${PROXMOX_SSH_PORT:-22}"
  ssh -p "${port}" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${user}@${host}" "$@"
}

proxmox_templates_update() {
  log_info "Updating LXC template index (pveam update)"
  proxmox_ssh_cmd "pveam update"
}

proxmox_templates_download_defaults() {
  # Developer notes
  #   - This is a starter set. Extend via a managed list under docs/questionnaires.md.
  config_load_exports
  local storage="${PROXMOX_TEMPLATE_STORAGE:-local}"

  proxmox_templates_update

  log_info "Downloading common LXC templates to storage '${storage}'"
  proxmox_ssh_cmd "pveam download ${storage} ubuntu-24.04-standard_24.04-2_amd64.tar.zst" || true
  proxmox_ssh_cmd "pveam download ${storage} debian-12-standard_12.7-1_amd64.tar.zst" || true

  log_ok "Template download step complete (best-effort)."
}
