#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Source control setup (git + GitHub CLI + safe clone/update)
# =============================================================================
# Purpose
#   A single executable to:
#     1) Configure git identity (interactive or non-interactive)
#     2) Authenticate GitHub CLI (token-preferred, or interactive)
#     3) Clone or fast-forward update the Homelab_2026 repo safely
#
# Usage
#   ./scripts/scm_setup.sh
#   TARGET_USER=gert ./scripts/scm_setup.sh
#   GIT_USER_NAME="Gert" GIT_USER_EMAIL="gert@example.com" ./scripts/scm_setup.sh
#   GH_TOKEN=<pat> ./scripts/scm_setup.sh --repo Fouchger/homelab_2026.1 --ref main
#
# Options
#   --target-user <user>   Run config/auth/clone as this user (via sudo). Default: current user
#   --repo <owner/repo>    GitHub repo to clone. Default: Fouchger/homelab_2026.1
#   --dir <path>           Target directory. Default: <target_home>/Fouchger/<repo_name>
#   --ref <branch>         Branch to pin + fast-forward update. Default: main
#   --host <hostname>      GitHub host for gh (github.com or GHES). Default: github.com
#   --skip-gh              Skip GitHub CLI auth step
#   --skip-clone           Skip clone/update step
#
# Environment
#   GIT_USER_NAME / GIT_USER_EMAIL  Non-interactive git identity
#   GITHUB_TOKEN / GH_TOKEN         Non-interactive gh authentication token
#
# Developer notes
#   - This script is intended to run after downstream tooling installs GitHub CLI.
#   - It is safe to re-run; updates are fast-forward only (no merges or rebases).
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCM_SCRIPT_DIR="${SCRIPT_DIR}"

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/lib/logging.sh"

log_init

# -----------------------------------------------------------------------------
# Minimal log wrappers
# -----------------------------------------------------------------------------
# These are intentionally tiny so they can be exported into a run_as_target
# subshell without dragging the full logging framework across.
info()  { if declare -F log_info >/dev/null 2>&1; then log_info "$*"; else printf '%s\n' "$*" >&2; fi; }
ok()    { if declare -F log_ok   >/dev/null 2>&1; then log_ok   "$*"; else printf '%s\n' "$*" >&2; fi; }
warn()  { if declare -F log_warn >/dev/null 2>&1; then log_warn "$*"; else printf '%s\n' "$*" >&2; fi; }
error() { if declare -F log_err  >/dev/null 2>&1; then log_err  "$*"; else printf '%s\n' "$*" >&2; fi; }

usage() {
  cat >&2 <<'EOT'
Usage: ./scripts/scm_setup.sh [options]

Options:
  --target-user <user>   Run as this user (via sudo)
  --repo <owner/repo>    Repo to clone (default: Fouchger/homelab_2026.1)
  --dir <path>           Target directory
  --ref <branch>         Branch to pin (default: main)
  --host <hostname>      GitHub host for gh (default: github.com)
  --skip-gh              Skip GitHub CLI auth
  --skip-clone           Skip clone/update
  -h, --help             Show help
EOT
}

need_cmd_or_warn() {
  local cmd="$1"
  if ! need_cmd "$cmd"; then
    warn "Missing dependency: ${cmd}. Some steps may be skipped."
    return 1
  fi
  return 0
}

# -----------------------------------------------------------------------------
# run_as_target
# -----------------------------------------------------------------------------
# Runs the provided bash snippet as TARGET_USER while keeping HOME correct.
# This version preserves colour-related env vars and avoids launching a login shell.
run_as_target() {
  local snippet="$1"

  if [[ "${TARGET_USER}" == "$(id -un)" ]]; then
    bash -c "$snippet"
    return $?
  fi

  if ! need_cmd sudo; then
    die "sudo is required to run as TARGET_USER='${TARGET_USER}', but sudo is not installed."
  fi

  # Preserve env vars that influence output formatting and config.
  # Avoid a login shell so we don't accidentally override env.
  sudo -u "${TARGET_USER}" \
    env -i \
      HOME="${TARGET_HOME}" \
      USER="${TARGET_USER}" \
      LOGNAME="${TARGET_USER}" \
      PATH="${PATH}" \
      TERM="${TERM:-}" \
      COLORTERM="${COLORTERM:-}" \
      NO_COLOR="${NO_COLOR:-}" \
      CLICOLOR="${CLICOLOR:-}" \
      CLICOLOR_FORCE="${CLICOLOR_FORCE:-}" \
      CATPPUCCIN_FLAVOUR="${CATPPUCCIN_FLAVOUR:-}" \
      HL_EMOJI="${HL_EMOJI:-}" \
      HL_DEBUG="${HL_DEBUG:-}" \
      GIT_USER_NAME="${GIT_USER_NAME:-}" \
      GIT_USER_EMAIL="${GIT_USER_EMAIL:-}" \
      GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
      GH_TOKEN="${GH_TOKEN:-}" \
      SCM_SCRIPT_DIR="${SCM_SCRIPT_DIR:-}" \
    bash -c "$snippet"
}

get_home_for_user() {
  local u="$1"
  getent passwd "$u" | cut -d: -f6
}

# -----------------------------------------------------------------------------
# Git config (handles interactive + non-interactive)
# -----------------------------------------------------------------------------
git_config() {
  info "Configuring git identity for user '${TARGET_USER}'..."

  # When scm_setup is invoked from a whiptail/dialog menu, stdin/stdout may be
  # redirected and prompts can end up effectively hidden "behind" the menu.
  # Prefer /dev/tty when available so interactive questions remain visible.
  local tty_in="/dev/tty"
  local tty_out="/dev/tty"

  prompt() {
    # Usage: prompt "Question" <varname>
    local question="${1:?question required}"
    local __varname="${2:?varname required}"
    local value=""

    if [[ -r "${tty_in}" && -w "${tty_out}" ]]; then
      # Print prompt to the terminal device directly.
      printf '%s' "${question}" >"${tty_out}"
      IFS= read -r value <"${tty_in}"
    elif [[ -t 0 ]]; then
      # Fallback for normal interactive use.
      read -r -p "${question}" value
    else
      return 1
    fi

    printf -v "${__varname}" '%s' "${value}"
  }

  # user.name
  if ! git config --global --get user.name >/dev/null 2>&1; then
    if [[ -n "${GIT_USER_NAME:-}" ]]; then
      git config --global user.name "${GIT_USER_NAME}"
      ok "Git user.name set."
    elif [[ -t 0 || -r "${tty_in}" ]]; then
      local git_username
      if prompt "Enter your Git username: " git_username; then
      [[ -n "$git_username" ]] || { error "Username can't be empty"; return 1; }
      git config --global user.name "$git_username"
      ok "Git user.name set."
    else
      warn "git user.name not set and no TTY available. Export GIT_USER_NAME to set it non-interactively."
    fi
  else
      warn "git user.name not set and no TTY available. Export GIT_USER_NAME to set it non-interactively."
    fi
  else
    info "Git user.name already set to: '$(git config --global --get user.name)'."
  fi

  # user.email
  if ! git config --global --get user.email >/dev/null 2>&1; then
    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
      git config --global user.email "${GIT_USER_EMAIL}"
      ok "Git user.email set."
    elif [[ -t 0 || -r "${tty_in}" ]]; then
      local git_email
      if prompt "Enter your Git email: " git_email; then
        while [[ -z "$git_email" ]]; do
          printf '%s\n' "Email can't be empty." >&2
          prompt "Enter your Git email: " git_email || break
      done
        if [[ -n "$git_email" ]]; then
      git config --global user.email "$git_email"
      ok "Git user.email set."
        fi
      else
        warn "git user.email not set and no TTY available. Export GIT_USER_EMAIL to set it non-interactively."
      fi
    else
      warn "git user.email not set and no TTY available. Export GIT_USER_EMAIL to set it non-interactively."
    fi
  else
    info "Git user.email already set to: '$(git config --global --get user.email)'."
  fi

  # Helpful defaults
  git config --global init.defaultBranch main >/dev/null 2>&1 || true
  git config --global push.default simple >/dev/null 2>&1 || true
  git config --global push.autoSetupRemote true >/dev/null 2>&1 || true
}

# -----------------------------------------------------------------------------
# GitHub CLI auth (token-preferred + setup-git)
# -----------------------------------------------------------------------------
github_config() {
  info "Configuring GitHub CLI for user '${TARGET_USER}' (host: ${GH_HOST})..."

  # Delegate to the single-source-of-truth login helper.
  # It safely validates tokens, avoids env var hijacking, and can repair hosts.yml.
  if ! "${SCM_SCRIPT_DIR}/gh_login.sh" --host "${GH_HOST}"; then
    error "GitHub CLI authentication failed."
    return 1
  fi

  ok "GitHub CLI authenticated."
}

# -----------------------------------------------------------------------------
# Repo pin + safe update helpers (no FETCH_HEAD)
# -----------------------------------------------------------------------------
git_pin_branch() {
  # Usage: git_pin_branch <repo_dir> [remote] [branch]
  local repo_dir="${1:?repo_dir required}"
  local remote="${2:-origin}"
  local branch="${3:-main}"

  git -C "$repo_dir" fetch --prune --tags "$remote" >/dev/null 2>&1 || true

  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$repo_dir" switch -q "$branch"
  elif git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/${remote}/${branch}"; then
    git -C "$repo_dir" switch -q -c "$branch" --track "${remote}/${branch}"
  else
    warn "Branch '$branch' not found locally or on ${remote} in $repo_dir"
    return 0
  fi

  git -C "$repo_dir" branch --set-upstream-to "${remote}/${branch}" "$branch" >/dev/null 2>&1 || true
  info "Pinned repo to ${branch} tracking ${remote}/${branch}"
}

git_fast_forward_update() {
  # Usage: git_fast_forward_update <repo_dir> [remote] [branch]
  local repo_dir="${1:?repo_dir required}"
  local remote="${2:-origin}"
  local branch="${3:-main}"

  if [[ -n "$(git -C "$repo_dir" status --porcelain 2>/dev/null || true)" ]]; then
    warn "Local changes detected in $repo_dir; skipping update to avoid overwriting work."
    warn "Commit/stash your changes, then re-run if you want to update."
    return 0
  fi

  git_pin_branch "$repo_dir" "$remote" "$branch"

  # Print a clear status before acting.
  # We treat GitHub as authoritative and only ever fast-forward local.
  local upstream_ref counts behind ahead
  upstream_ref="${remote}/${branch}"

  if ! git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/${upstream_ref}"; then
    warn "Upstream ref '${upstream_ref}' not found; skipping update status check."
    return 0
  fi

  counts="$(git -C "$repo_dir" rev-list --left-right --count "${upstream_ref}...HEAD" 2>/dev/null || true)"
  behind="${counts%% *}"
  ahead="${counts##* }"
  behind="${behind:-0}"
  ahead="${ahead:-0}"

  info "Sync status for $repo_dir (${branch}): behind=${behind}, ahead=${ahead}"

  if [[ "$behind" -eq 0 && "$ahead" -eq 0 ]]; then
    ok "Already up to date with ${upstream_ref}."
    return 0
  fi

  if [[ "$behind" -gt 0 && "$ahead" -eq 0 ]]; then
    if ! git -C "$repo_dir" pull --ff-only "$remote" "$branch" >/dev/null 2>&1; then
      warn "Non fast-forward update required in $repo_dir (diverged or remote was force-pushed)."
      warn "Manual intervention recommended before proceeding."
      return 0
    fi

    ok "Updated $repo_dir to latest ${upstream_ref} (fast-forward)."
    return 0
  fi

  if [[ "$behind" -eq 0 && "$ahead" -gt 0 ]]; then
    warn "Local repo is ${ahead} commit(s) ahead of ${upstream_ref}."
    warn "GitHub is authoritative; stopping short of pushing. Review your local commits before proceeding."
    return 0
  fi

  warn "Local and ${upstream_ref} have diverged (behind=${behind}, ahead=${ahead})."
  warn "GitHub is authoritative; stopping to avoid overwriting local history."
  return 0
}

# -----------------------------------------------------------------------------
# Clone or update repo (as TARGET_USER) — pinned branch, safe re-runs
# -----------------------------------------------------------------------------
clone_via_gh() {
  # Usage: clone_via_gh <owner/repo> <target_dir> [<ref>]
  local repo="$1" dir="$2" ref="${3:-main}"

  # Disable any interactive Git password prompts just in case.
  export GIT_TERMINAL_PROMPT=0
  export GIT_ASKPASS=/bin/echo

  if [[ -d "$dir/.git" ]]; then
    info "Repo already exists at '$dir'; updating (pinned to '${ref}')..."
    git -C "$dir" remote set-url origin "https://github.com/${repo}.git" >/dev/null 2>&1 || true
    git_fast_forward_update "$dir" origin "$ref"
    return 0
  fi

  if command -v gh >/dev/null 2>&1; then
    info "Cloning '${repo}' into '${dir}' via gh..."
    gh repo clone "$repo" "$dir" -- --no-tags --filter=blob:none
  else
    warn "gh not available; cloning via git instead (HTTPS)."
    git clone --filter=blob:none --no-tags "https://github.com/${repo}.git" "$dir"
  fi

  git_pin_branch "$dir" origin "$ref"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
TARGET_USER="${TARGET_USER:-$(id -un)}"
TARGET_HOME="$(get_home_for_user "${TARGET_USER}" || true)"
TARGET_HOME="${TARGET_HOME:-${HOME}}"

REPO_SLUG="Fouchger/homelab_2026.1"
REPO_DIR=""
REF="main"
GH_HOST="github.com"
SKIP_GH="false"
SKIP_CLONE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-user) TARGET_USER="${2:?}"; shift 2 ;;
    --repo) REPO_SLUG="${2:?}"; shift 2 ;;
    --dir) REPO_DIR="${2:?}"; shift 2 ;;
    --ref) REF="${2:?}"; shift 2 ;;
    --host) GH_HOST="${2:?}"; shift 2 ;;
    --skip-gh) SKIP_GH="true"; shift ;;
    --skip-clone) SKIP_CLONE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown argument: $1"; usage; exit 2 ;;
  esac
 done

TARGET_HOME="$(get_home_for_user "${TARGET_USER}" || true)"
TARGET_HOME="${TARGET_HOME:-${HOME}}"

if [[ -z "${REPO_DIR}" ]]; then
  # Default: <home>/Fouchger/<repo_name>
  repo_name="${REPO_SLUG##*/}"
  REPO_DIR="${TARGET_HOME}/Fouchger/${repo_name}"
fi

info "Target user: ${TARGET_USER}"
info "Target home: ${TARGET_HOME}"
info "Repo: ${REPO_SLUG}"
info "Dir: ${REPO_DIR}"
info "Ref: ${REF}"

need_cmd_or_warn git

# Run git config as TARGET_USER so it writes to their ~/.gitconfig
run_as_target "$(declare -f info ok warn error); $(declare -f git_config); git_config"

if [[ "${SKIP_GH}" != "true" ]]; then
  run_as_target "export GH_HOST='${GH_HOST}'; $(declare -f info ok warn error); $(declare -f github_config); github_config"
else
  info "Skipping GitHub CLI auth (--skip-gh)."
fi

if [[ "${SKIP_CLONE}" != "true" ]]; then
  # Ensure parent exists as the target user
  parent_dir="$(dirname -- "${REPO_DIR}")"
  run_as_target "mkdir -p -- '${parent_dir}'"

  run_as_target "export REPO_SLUG='${REPO_SLUG}'; export REPO_DIR='${REPO_DIR}'; export REF='${REF}'; \
    $(declare -f info ok warn error); $(declare -f git_pin_branch); $(declare -f git_fast_forward_update); $(declare -f clone_via_gh); clone_via_gh \"${REPO_SLUG}\" \"${REPO_DIR}\" \"${REF}\""
else
  info "Skipping clone/update (--skip-clone)."
fi

ok "Source control setup complete."
