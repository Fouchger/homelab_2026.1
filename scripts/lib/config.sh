#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Config and questionnaires
# =============================================================================
# Purpose
#   Handles capturing, validating, and persisting user configuration.
#
# Storage
#   - Primary: generated_configs/homelab.env (dotenv style)
#   - Generated files are gitignored.
#
# Developer notes
#   - Keep this idempotent. Re-running should update values, not duplicate them.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/logging.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/ui.sh"

HL_CONFIG_DIR="${REPO_ROOT}/generated_configs"
HL_ENV_FILE="${HL_ENV_FILE:-${HL_CONFIG_DIR}/homelab.env}"

config_init() {
  ensure_dir "${HL_CONFIG_DIR}"
  if [[ ! -f "${HL_ENV_FILE}" ]]; then
    cat >"${HL_ENV_FILE}" <<'EOV'
# homelab_2026.1 configuration (generated)
# This file is safe to regenerate. Do not commit secrets here.
EOV
  fi
}

config_get() {
  local key="$1"
  [[ -f "${HL_ENV_FILE}" ]] || return 1
  awk -F= -v k="${key}" '$1==k {sub(/^[^=]+=/,""); print; exit}' "${HL_ENV_FILE}"
}

config_set() {
  local key="$1" value="$2"
  [[ -n "${key}" ]] || return 1
  config_init

  if grep -qE "^${key}=" "${HL_ENV_FILE}"; then
    # Use a safe delimiter and escape backslashes.
    local esc
    esc="${value//\\/\\\\}"
    sed -i -E "s|^${key}=.*$|${key}=${esc}|" "${HL_ENV_FILE}"
  else
    printf '%s=%s\n' "${key}" "${value}" >>"${HL_ENV_FILE}"
  fi
}

questionnaire_core() {
  config_init
  ui_ensure_dialog || true

  ui_msg "Questionnaire" "We'll capture core settings for Proxmox, network, and admin node. You can re-run this at any time."

  local proxmox_host proxmox_port proxmox_node
  proxmox_host="$(ui_prompt "Proxmox API hostname or IP" "$(config_get PROXMOX_HOST || true)")" || true
  proxmox_port="$(ui_prompt "Proxmox API port" "$(config_get PROXMOX_PORT || true)")" || true
  proxmox_node="$(ui_prompt "Default Proxmox node name" "$(config_get PROXMOX_NODE || true)")" || true

  proxmox_port="${proxmox_port:-8006}"

  config_set PROXMOX_HOST "${proxmox_host}"
  config_set PROXMOX_PORT "${proxmox_port}"
  config_set PROXMOX_NODE "${proxmox_node}"

  local lan_cidr gateway_ip dns_upstream
  lan_cidr="$(ui_prompt "LAN CIDR (for DHCP/DNS planning)" "$(config_get LAN_CIDR || true)")" || true
  gateway_ip="$(ui_prompt "Gateway IP (e.g. MikroTik LAN interface)" "$(config_get GATEWAY_IP || true)")" || true
  dns_upstream="$(ui_prompt "Upstream DNS (comma-separated)" "$(config_get DNS_UPSTREAM || true)")" || true

  config_set LAN_CIDR "${lan_cidr}"
  config_set GATEWAY_IP "${gateway_ip}"
  config_set DNS_UPSTREAM "${dns_upstream}"

  local flavour emoji
  flavour="$(ui_prompt "Catppuccin flavour (latte|frappe|macchiato|mocha)" "$(config_get CATPPUCCIN_FLAVOUR || true)")" || true
  emoji="$(ui_prompt "Emoji output (1=on,0=off)" "$(config_get HL_EMOJI || true)")" || true

  flavour="${flavour:-mocha}"
  emoji="${emoji:-1}"

  config_set CATPPUCCIN_FLAVOUR "${flavour}"
  config_set HL_EMOJI "${emoji}"

  log_ok "Saved config to ${HL_ENV_FILE}"
}

config_load_exports() {
  # Exports config keys for use by subscripts.
  config_init
  # shellcheck disable=SC1090
  set -a
  source "${HL_ENV_FILE}"
  set +a
}
