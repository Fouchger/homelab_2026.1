#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Ansible helpers
# =============================================================================
# Purpose
#   Wrapper for running Ansible playbooks with consistent config loading.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/config.sh"

ANSIBLE_DIR="${REPO_ROOT}/ansible"

ansible_require() {
  need_cmd ansible-playbook || die "ansible-playbook not found. Run: make bootstrap"
}

ansible_run() {
  # Usage: ansible_run <playbook> [extra_args...]
  local playbook="$1"; shift || true

  ansible_require
  config_load_exports

  local pb_path="${ANSIBLE_DIR}/playbooks/${playbook}"
  [[ -f "${pb_path}" ]] || die "Playbook not found: ${pb_path}"

  local inv="${ANSIBLE_DIR}/inventory/hosts.ini"
  [[ -f "${inv}" ]] || die "Inventory not found: ${inv}"

  (cd "${ANSIBLE_DIR}" && run_cmd ansible-playbook -i "${inv}" "${pb_path}" "$@")
}
