#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Initial checkout and kick-off
# =============================================================================
# Purpose
#   Prepare a fresh Ubuntu admin node to run this repository by installing only
#   what is required to:
#     1) clone the repo
#     2) run the Makefile entry points
#
#   Everything beyond git + make must be installed downstream (e.g. via Ansible
#   and Terraform).
#
# Usage
#   curl -fsSL <raw-init-url> | bash
#   ./scripts/init.sh
#
# Configuration
#   REPO_SLUG   - GitHub repo in owner/name form (default: Fouchger/homelab_2026.1)
#   REPO_URL    - Git URL to clone (default: https://github.com/${REPO_SLUG}.git)
#   BRANCH      - Branch to checkout (default: main)
#   INSTALL_DIR - Where to place the repo (default: ${HOME}/Fouchger/homelab_2026.1)
#
# Developer notes
#   - Keep this script dependency-light (no repo libraries).
#   - Avoid interactive prompts except for launching the menu.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

REPO_SLUG="${REPO_SLUG:-Fouchger/homelab_2026.1}"
REPO_URL="${REPO_URL:-https://github.com/${REPO_SLUG}.git}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/Fouchger/homelab_2026.1}"

log()  { printf '[init] %s\n' "$*"; }
err()  { printf '[init][ERROR] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

ensure_prereqs() {
  have apt-get || die "apt-get not found. This script currently supports Ubuntu/Debian." 
  have sudo || die "sudo is required to install prerequisites." 

  log "Installing minimal prerequisites (git, make)"
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends git make
}

checkout_repo() {
  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    log "Repo already present at ${INSTALL_DIR}." 
    return 0
  fi

  log "Cloning ${REPO_URL} (${BRANCH}) to ${INSTALL_DIR}" 
  git clone -b "${BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
}

sync_repo_safely() {
  # Delegate all sync logic (status, ff-only, divergence detection) to scm_setup.
  if [[ ! -x "${INSTALL_DIR}/scripts/scm_setup.sh" ]]; then
    die "Expected ${INSTALL_DIR}/scripts/scm_setup.sh not found or not executable."
  fi

  log "Checking repo sync status (GitHub authoritative, ff-only)."
  "${INSTALL_DIR}/scripts/scm_setup.sh" \
    --skip-gh \
    --repo "${REPO_SLUG}" \
    --dir "${INSTALL_DIR}" \
    --ref "${BRANCH}" \
    --target-user "$(id -un)"
}

run_make_targets() {
  cd "${INSTALL_DIR}" 

  # Ensure scripts are executable (idempotent).
  if [[ -f "./scripts/make-executable.sh" ]]; then
    chmod +x ./scripts/make-executable.sh
    ./scripts/make-executable.sh
  fi

  log "Running bootstrap (minimal prerequisites only)"
  make bootstrap

  if [[ -t 0 && -t 1 ]]; then
    log "Launching menu" 
    make menu
  else
    log "Non-interactive session detected. Run 'make menu' once you are on a TTY." 
  fi
}

main() {
  ensure_prereqs
  checkout_repo
  run_make_targets
  sync_repo_safely
}

main "$@"
