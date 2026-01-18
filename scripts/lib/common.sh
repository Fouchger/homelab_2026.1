#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Common library
# =============================================================================
# Purpose
#   Shared helpers used across scripts (paths, OS checks, privilege helpers).
#
# Usage
#   Source this file:
#     source "${REPO_ROOT}/scripts/lib/common.sh"
#
# Developer notes
#   - Keep functions small and side-effect free.
#   - Do not print from library functions unless explicitly a log_* helper.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# Resolve repo root reliably.
repo_root() {
  local d
  d="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  printf '%s' "${d}"
}

REPO_ROOT="$(repo_root)"

need_cmd() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_dir() {
  local d="$1"
  [[ -n "${d}" ]] || return 1
  mkdir -p -- "${d}"
}

is_tty() { [[ -t 1 ]]; }
