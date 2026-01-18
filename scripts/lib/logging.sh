#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Logging
# =============================================================================
# Purpose
#   Consistent structured logging to stdout and a per-run logfile.
#
# Notes
#   - Log file path defaults to generated_configs/logs/<timestamp>.log
#   - Set HL_DEBUG=0 to reduce command output.
#
# Developer notes
#   - Avoid calling echo directly in scripts; use log_info/log_ok/log_warn/log_err.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/colours.sh"

HL_DEBUG="${HL_DEBUG:-1}"

HL_LOG_DIR="${HL_LOG_DIR:-${REPO_ROOT}/generated_configs/logs}"
HL_LOG_FILE=""

log_init() {
  colour_init "${CATPPUCCIN_FLAVOUR:-mocha}"
  ensure_dir "${HL_LOG_DIR}"
  local ts
  ts="$(date -Iseconds | tr ':' '-')"
  HL_LOG_FILE="${HL_LOG_DIR}/run_${ts}.log"
  : >"${HL_LOG_FILE}"
}

_log_line() {
  local level="$1"; shift || true
  local msg="$*"
  printf '%s [%s] %s\n' "$(date -Iseconds)" "${level}" "${msg}" >>"${HL_LOG_FILE}"
}

_log_console() {
  local token="$1"; shift || true
  local msg="$*"
  if is_tty; then
    printf '%s%s%s\n' "$(hl_emoji "${token}")" "$(hl_fmt "${token}" "${msg}")" "$(hl_fmt accent "")" >&2
  else
    printf '%s\n' "${msg}" >&2
  fi
}

log_info() { _log_line INFO "$*"; _log_console info "$*"; }
log_ok() { _log_line OK "$*"; _log_console ok "$*"; }
log_warn() { _log_line WARN "$*"; _log_console warn "$*"; }
log_err() { _log_line ERROR "$*"; _log_console err "$*"; }

die() {
  log_err "$*"
  exit 1
}

run_cmd() {
  # Usage: run_cmd <cmd> [args...]
  log_info "CMD: $*"
  if [[ "${HL_DEBUG}" == "1" ]]; then
    "$@" 2>&1 | tee -a "${HL_LOG_FILE}"
    return "${PIPESTATUS[0]}"
  fi
  "$@" >>"${HL_LOG_FILE}" 2>&1
}
