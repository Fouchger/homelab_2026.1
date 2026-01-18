#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - GitHub CLI login helper
# =============================================================================
# Purpose
#   Ensure a working GitHub CLI login for the selected host (default github.com)
#   and repair common auth/config issues.
#
# Usage
#   GH_TOKEN=<your_pat> ./scripts/gh_login.sh
#   ./scripts/gh_login.sh
#
# Notes
#   - Safe to EXECUTE or SOURCE: when sourced it will "return" instead of "exit" so it won't kill your SSH session.
#   - If not logged in, validates token then performs gh auth login.
#   - Can back up and repair a corrupt gh hosts.yml, then re-authenticate.

set -Eeuo pipefail
IFS=$'\n\t'

# Ensures a working GitHub CLI login for a given host (default: github.com).
# If not logged in, it will:
#  - validate $GH_TOKEN (or prompt securely) with the GitHub API
#  - login to gh while temporarily unsetting GH_TOKEN/GITHUB_TOKEN so creds are stored
#  - configure git to use gh's auth
#  - auto-repair corrupt/stale hosts.yml by backing it up and re-authing
#  - optionally clean the root user's gh config if we have sudo
#
# Usage:
#   GH_TOKEN=<your_pat> ./gh_login.sh                    # non-interactive
#   ./gh_login.sh                                       # will prompt for token
#   ./gh_login.sh --host github.mycompany.com           # GitHub Enterprise
#   ./gh_login.sh --fix-root                            # also tidy /root config if possible
#
# Returns/Exits 0 when authenticated; non-zero otherwise.
#
# Important
#   If you include this script from ~/.bashrc or /etc/profile, source it safely:
#     . /path/to/homelab_2026.1/scripts/gh_login.sh
#   This script avoids "exit" when sourced, preventing SSH session termination.

api_base() {
  # GitHub.com uses api.github.com. GitHub Enterprise typically uses /api/v3.
  local host="$1"
  if [[ "$host" == "github.com" ]]; then
    printf '%s' "https://api.github.com"
  else
    printf '%s' "https://${host}/api/v3"
  fi
}

ensure_gh_login_main() {
  HOST="github.com"
  FIX_ROOT="false"

  log()   { printf "[gh-ensure] %s\n" "$*"; }
  warn()  { printf "[gh-ensure][WARN] %s\n" "$*" >&2; }

  # Use "return" so it's safe when sourced; the wrapper decides whether to exit.
  die() {
    printf "[gh-ensure][ERROR] %s\n" "$*" >&2
    return 1
  }

  have() { command -v "$1" >/dev/null 2>&1; }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)      HOST="${2:-}"; shift 2 ;;
      --fix-root)  FIX_ROOT="true"; shift ;;
      *)           die "Unknown argument: $1" ;;
    esac
  done

  # Resolve config paths
  USER_HOME="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6 2>/dev/null || echo "/root")}"
  CFG_DIR="${XDG_CONFIG_HOME:-"$USER_HOME/.config"}"
  HOSTS_YML="$CFG_DIR/gh/hosts.yml"

  # 0) Preconditions
  have gh || die "GitHub CLI 'gh' is not installed. See https://cli.github.com/"
  have curl || die "'curl' is required."

  api_base() {
    # GitHub.com uses api.github.com. GitHub Enterprise Server typically uses
    # https://<host>/api/v3 for REST.
    local host="$1"
    if [[ "$host" == "github.com" ]]; then
      printf '%s' 'https://api.github.com'
    else
      printf '%s' "https://${host}/api/v3"
    fi
  }

  # Helper: check if current gh store can call the API (without env token)
  check_logged_in() {
    (unset GITHUB_TOKEN GH_TOKEN; gh api -H "Accept: application/vnd.github+json" --hostname "$HOST" /user >/dev/null 2>&1)
  }

  # Helper: validate a token directly against the GitHub API
  # - returns 0 if valid (HTTP 200), non-zero otherwise
  # - emits headers to a temp file for debugging scopes/SSO
  validate_token() {
    local token="$1" tmp code scopes
    tmp="$(mktemp)"
    local base
    base="$(api_base "$HOST")"

    code="$(curl -sS -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/vnd.github+json" \
      "${base}/user" || true)"

    # Save response headers for debugging (scopes/SSO info)
    curl -sS -D "$tmp" -o /dev/null \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/vnd.github+json" \
      "${base}/user" >/dev/null 2>&1 || true

    if [[ "$code" != "200" ]]; then
      warn "Token validation HTTP status: $code (expected 200)."
      warn "If your org uses SSO, ensure this PAT is authorised for the organisation."
      warn "Check scopes in the response headers (X-OAuth-Scopes) saved at: $tmp"
      return 1
    fi

    # Optional: show scopes briefly (non-fatal if missing)
    if grep -qi '^x-oauth-scopes:' "$tmp" 2>/dev/null; then
      scopes="$(grep -i '^x-oauth-scopes:' "$tmp" | sed 's/^[^:]*:\s*//I')"
      log "Token scopes: ${scopes:-unknown}"
    fi

    rm -f "$tmp" || true
    return 0
  }

  # Helper: perform login using token while ensuring env vars don't hijack the flow
  login_with_token() {
    local token="${GH_TOKEN-}"
    if [[ -z "${token}" ]]; then
      read -r -s -p "Enter GitHub token for $HOST: " token
      echo
    fi
    [[ -n "${token}" ]] || die "No token provided."

    # Validate the token first; fail early with useful hints
    if ! validate_token "$token"; then
      die "Token is invalid or not SSO-authorised."
    fi

    # Do NOT let GH_TOKEN/GITHUB_TOKEN override stdin and block credential storage.
    # We temporarily clear them for the login command only.
    if ! (env -u GH_TOKEN -u GITHUB_TOKEN bash -lc 'gh auth login --hostname "'"$HOST"'" --with-token' <<<"$token" >/dev/null); then
      die "gh auth login failed. Check token scopes/SSO authorisation."
    fi

    # Configure git to use gh auth; HTTPS is easiest across environments
    gh auth setup-git >/dev/null 2>&1 || true
    gh config set git_protocol https >/dev/null 2>&1 || true
  }

  # Helper: backup and reset hosts.yml, then re-login
  repair_hosts_yml_and_reauth() {
    if [[ -f "$HOSTS_YML" ]]; then
      local stamp backup
      stamp="$(date +%Y%m%d-%H%M%S)"
      backup="${HOSTS_YML}.bak.${stamp}"
      warn "Backing up corrupt/stale hosts file: $HOSTS_YML -> $backup"
      mv "$HOSTS_YML" "$backup"
    fi
    login_with_token
  }

  # Helper: optionally clean root's hosts.yml if we can sudo (common 'sudo' gotcha)
  maybe_fix_root_context() {
    [[ "$FIX_ROOT" == "true" ]] || return 0
    if have sudo && sudo -n true 2>/dev/null; then
      if sudo test -f /root/.config/gh/hosts.yml; then
        local stamp
        stamp="$(date +%Y%m%d-%H%M%S)"
        warn "Root context has a stale /root/.config/gh/hosts.yml; backing up."
        sudo mv /root/.config/gh/hosts.yml "/root/.config/gh/hosts.yml.bak.${stamp}" || true
        if [[ -n "${GH_TOKEN-}" ]]; then
          warn "Re-authenticating gh for root context as well."
          sudo bash -lc 'env -u GH_TOKEN -u GITHUB_TOKEN bash -lc '\''gh auth login --hostname "'"$HOST"'" --with-token'\'' <<<"$GH_TOKEN" >/dev/null' || true
        fi
      fi
    else
      warn "Skipping root context fix (no passwordless sudo). Use --fix-root with sudo if needed."
    fi
  }

  # 1) Fast-path: already logged in?
  if check_logged_in; then
    log "Already authenticated to $HOST."
    return 0
  fi

  # 2) Try a straight login (uses GH_TOKEN or prompts)
  log "Not authenticated to $HOST. Attempting login…"
  login_with_token

  # 3) Verify; if still not OK, attempt auto-repair of hosts.yml then retry
  if check_logged_in; then
    log "Authenticated successfully to $HOST."
    return 0
  fi

  warn "Auth still failing; attempting hosts.yml repair and re-auth."
  repair_hosts_yml_and_reauth

  # 4) Verify again
  if check_logged_in; then
    log "Authenticated successfully after repair."
    maybe_fix_root_context
    return 0
  fi

  # 5) As a last resort, attempt logout then login once more
  warn "Final attempt: force logout then re-login."
  (gh auth logout --hostname "$HOST" -y >/dev/null 2>&1) || true
  login_with_token

  if check_logged_in; then
    log "Authenticated successfully after forced re-login."
    maybe_fix_root_context
    return 0
  fi

  die "Unable to authenticate to $HOST. Check token validity, scopes (e.g., Contents: Read or repo), and SSO approval for your organisation."
}

# Wrapper: if executed, exit with status; if sourced, return with status.
# This prevents "exit" from killing an interactive shell (and your SSH session).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ensure_gh_login_main "$@"
  exit $?
else
  ensure_gh_login_main "$@"
  return $?
fi
