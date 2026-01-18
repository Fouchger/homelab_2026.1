#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Bootstrap
# =============================================================================
# Purpose
#   Prepare a fresh Ubuntu VM/LXC to run this repo. Installs only what is
#   required to clone the repo and execute the Makefile entry points.
#
# Usage
#   from repo root:
#     make bootstrap
#   ...or directly:
#     scripts/bootstrap.sh
#
# Developer notes
#   - Keep this minimal. Use Ansible for anything larger than core prerequisites.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/common.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

main() {
  log_init

  log_info "Bootstrap starting"

  if ! need_cmd sudo; then
    die "sudo is required on the admin node. Install sudo and re-run."
  fi

  log_info "Updating apt index"
  run_cmd as_root apt-get update

  local -a pkgs=(
    git
    make
  )

  log_info "Installing minimal prerequisites (git, make)"
  run_cmd as_root apt-get install -y --no-install-recommends "${pkgs[@]}"

  log_ok "Bootstrap complete"
  log_info "Next: make menu (interactive)"
  log_info "Log: ${HL_LOG_FILE}"
}

main "$@"
