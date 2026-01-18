#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - UI helpers
# =============================================================================
# Purpose
#   Terminal UI helpers (dialog-based when available, text fallback otherwise).
#
# Developer notes
#   - We deliberately keep all UI in one place to ease future changes.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/logging.sh"

ui_has_dialog() { command -v dialog >/dev/null 2>&1; }

ui_ensure_dialog() {
  if ui_has_dialog; then
    return 0
  fi
  log_warn "'dialog' not found. Installing (requires sudo)."
  run_cmd as_root apt-get update
  run_cmd as_root apt-get install -y --no-install-recommends dialog
}

ui_msg() {
  local title="$1"; shift || true
  local body="$*"
  if ui_has_dialog && is_tty; then
    dialog --title "${title}" --msgbox "${body}" 12 80
  else
    log_info "${title}: ${body}"
  fi
}

ui_yesno() {
  local title="$1"; shift || true
  local body="$*"
  if ui_has_dialog && is_tty; then
    dialog --title "${title}" --yesno "${body}" 12 80
    return $?
  fi

  printf '%s (y/N): ' "${body}" >&2
  read -r ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

ui_prompt() {
  local prompt="$1"
  local default_val="${2:-}"

  if ui_has_dialog && is_tty; then
    local tmp
    tmp="$(mktemp)"
    dialog --title "Input" --inputbox "${prompt}" 10 80 "${default_val}" 2>"${tmp}" || {
      rm -f -- "${tmp}"
      return 1
    }
    cat "${tmp}"
    rm -f -- "${tmp}"
    return 0
  fi

  if [[ -n "${default_val}" ]]; then
    printf '%s [%s]: ' "${prompt}" "${default_val}" >&2
  else
    printf '%s: ' "${prompt}" >&2
  fi
  read -r v
  printf '%s' "${v:-${default_val}}"
}
