#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Packer runners
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

packer_ensure() {
  if command -v packer >/dev/null 2>&1; then return 0; fi
  log_warn "Packer not found. Install it via your preferred method (HashiCorp repo or asdf)."
  die "Packer required"
}
