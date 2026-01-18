#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Terraform helpers
# =============================================================================
# Purpose
#   Thin wrapper for terraform actions with consistent logging and environment loading.
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/config.sh"

terraform_env_dir() {
  local env_name="$1"
  printf '%s' "${REPO_ROOT}/terraform/environments/${env_name}"
}

terraform_require() {
  need_cmd terraform || die "terraform not found. Run: make bootstrap"
}

terraform_init() {
  local env_name="$1"
  terraform_require
  config_load_exports
  local d
  d="$(terraform_env_dir "${env_name}")"
  [[ -d "${d}" ]] || die "Unknown terraform environment: ${env_name}"

  (cd "${d}" && run_cmd terraform init)
}

terraform_plan() {
  local env_name="$1"
  terraform_require
  config_load_exports
  local d
  d="$(terraform_env_dir "${env_name}")"
  (cd "${d}" && run_cmd terraform plan)
}

terraform_apply() {
  local env_name="$1"
  terraform_require
  config_load_exports
  local d
  d="$(terraform_env_dir "${env_name}")"
  (cd "${d}" && run_cmd terraform apply)
}

terraform_destroy() {
  local env_name="$1"
  terraform_require
  config_load_exports
  local d
  d="$(terraform_env_dir "${env_name}")"
  (cd "${d}" && run_cmd terraform destroy)
}
