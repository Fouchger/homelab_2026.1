#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Git helpers
# =============================================================================
# Purpose
#   Clone or update git repositories (used for pulling external modules, templates).
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/logging.sh"

git_sync() {
  # Usage: git_sync <repo_url> <dest_dir> [branch]
  local repo_url="$1" dest_dir="$2" branch="${3:-}"
  [[ -n "${repo_url}" && -n "${dest_dir}" ]] || die "git_sync requires repo_url and dest_dir"

  if [[ -d "${dest_dir}/.git" ]]; then
    log_info "Updating repo: ${dest_dir}"
    run_cmd git -C "${dest_dir}" fetch --all --prune
    if [[ -n "${branch}" ]]; then
      run_cmd git -C "${dest_dir}" checkout "${branch}"
      run_cmd git -C "${dest_dir}" pull --ff-only
    else
      run_cmd git -C "${dest_dir}" pull --ff-only
    fi
    return 0
  fi

  log_info "Cloning repo: ${repo_url} -> ${dest_dir}"
  ensure_dir "$(dirname -- "${dest_dir}")"
  if [[ -n "${branch}" ]]; then
    run_cmd git clone --branch "${branch}" --depth 1 "${repo_url}" "${dest_dir}"
  else
    run_cmd git clone --depth 1 "${repo_url}" "${dest_dir}"
  fi
}
