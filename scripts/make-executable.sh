#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Make scripts executable
# =============================================================================
# Purpose
#   Ensure shell entrypoints in this repository are executable.
#
# Usage
#   ./scripts/make-executable.sh
#
# Notes
#   - Idempotent and safe to re-run.
#   - Operates on the git root when available.
#   - Intentionally limited to shell scripts; Python tooling is installed and
#     invoked downstream via Ansible/Terraform.
# =============================================================================
set -euo pipefail
set -o errtrace

# Resolve repo root (prefer git when available)
if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  BASE_DIR="$git_root"
else
  BASE_DIR="$(pwd)"
fi

echo "Working directory: ${BASE_DIR}"

# 1) Make all *.sh files executable (recursive), excluding .git
echo "Making all *.sh files executable..."
while IFS= read -r -d '' file; do
  chmod +x "$file"
  echo "  chmod +x $file"
done < <(
  find "$BASE_DIR" \
    -path '*/.git/*' -prune -o \
    -type f -name "*.sh" -print0
)

# 2) Make key Python entrypoints executable (if present)
TARGETS=(
  "$BASE_DIR/scripts/menu.sh"

)

echo "Making target Python scripts executable (if they exist)..."
for target in "${TARGETS[@]}"; do
  if [[ -f "$target" ]]; then
    chmod +x "$target"
    echo "  chmod +x $target"
  else
    echo "  Skipped (not found): $target"
  fi
done

echo "Done."
