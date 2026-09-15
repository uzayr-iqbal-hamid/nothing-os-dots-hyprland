#!/usr/bin/env bash
# Apply the NOTHING-SHELL patches to JaKooLit's vendor files in ~/.config.
# Safe to re-run: a patch that is already applied is skipped. Uses git apply (works outside a repo).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HOME/.config"
for p in "$here"/*.patch; do
  name=$(basename "$p")
  if git apply --check -R "$p" >/dev/null 2>&1; then
    echo "already applied: $name"
  elif git apply --check "$p" >/dev/null 2>&1; then
    git apply "$p" && echo "applied: $name"
  else
    echo "SKIPPED (does not apply cleanly, edit by hand): $name"
    echo "  the lines to change are marked NOTHING-SHELL inside the patch"
  fi
done
