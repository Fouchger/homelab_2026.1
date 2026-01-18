#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Main menu
# =============================================================================
# Purpose
#   Operator-friendly terminal UI for managing the homelab.
#
# Features
#   - `dialog` menu navigation with spacebar selection patterns.
#   - Works in TTY-only environments; falls back to text prompts if dialog is absent.
#   - Central entry point for questionnaires, Proxmox bootstrap, Terraform and Ansible tasks.
#
# Usage
#   make menu
#   ./scripts/menu.sh
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/ui.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/config.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/proxmox.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/terraform.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/ansible.sh"

choose_tf_env() {
  local env
  env="$(ui_prompt "Terraform environment (dev|prod)" "dev")" || return 1
  case "${env}" in
    dev|prod) printf '%s' "${env}" ;;
    *) ui_msg "Invalid" "Environment must be dev or prod"; return 1 ;;
  esac
}

menu_loop() {
  ui_ensure_dialog || true
  log_init

  while true; do
    local tmp choice
    tmp="$(mktemp)"

    if ui_has_dialog && is_tty; then
      if ! dialog --title "homelab_2026.1" \
        --menu "Choose an action:" 22 90 12 \
        1 "Run questionnaire (core settings)" \
        2 "Proxmox: bootstrap API token" \
        3 "Proxmox: download common LXC templates" \
        4 "Terraform: init" \
        5 "Terraform: plan" \
        6 "Terraform: apply" \
        7 "Terraform: destroy" \
        8 "Ansible: configure admin node" \
        9 "Ansible: deploy core services (DHCP/DNS/AD placeholders)" \
        10 "Exit" \
        2>"${tmp}"; then
        rm -f -- "${tmp}"
        break
      fi
      choice="$(<"${tmp}")"
    else
      printf '\n1) Questionnaire\n2) Proxmox API token\n3) Download templates\n4) Terraform init\n5) Terraform plan\n6) Terraform apply\n7) Terraform destroy\n8) Ansible admin node\n9) Ansible core services\n10) Exit\n\nSelect: ' >&2
      read -r choice
    fi

    rm -f -- "${tmp}" || true

    case "${choice}" in
      1) questionnaire_core ;;
      2) "${REPO_ROOT}/scripts/proxmox/bootstrap-api-token.sh" ;;
      3) proxmox_templates_download_defaults ;;
      4) terraform_init "$(choose_tf_env)" ;;
      5) terraform_plan "$(choose_tf_env)" ;;
      6) terraform_apply "$(choose_tf_env)" ;;
      7) terraform_destroy "$(choose_tf_env)" ;;
      8) ansible_run "admin_node.yml" ;;
      9) ansible_run "core_services.yml" ;;
      10|"" ) break ;;
      *) ui_msg "Unknown" "Invalid selection" ;;
    esac
  done
}

menu_loop "$@"
