#!/usr/bin/env bash
# Arch / Hyprland launcher — thin wrapper around the git package.
#
# Single source of truth: ~/soundsbored (Python).
#   Linux → rofi backend (this machine)
#   macOS → fzf backend (same package, same menus/clips logic)
#
# Legacy bash implementation (if you need it):
#   ~/.config/hyprgruv/scripts/soundsbored.sh.legacy
set -euo pipefail

REPO="${SOUNDSBORED_REPO:-${HOME}/soundsbored}"
VENV_BIN="${REPO}/.venv/bin/soundsbored"

if [[ -x "$VENV_BIN" ]]; then
  exec "$VENV_BIN" "$@"
fi

# Fallback: package on PATH that is not this wrapper
if command -v soundsbored >/dev/null 2>&1; then
  REAL="$(command -v soundsbored)"
  # Avoid infinite loop if PATH points here
  if [[ "$(readlink -f "$REAL" 2>/dev/null || echo "$REAL")" != "$(readlink -f "$0" 2>/dev/null || echo "$0")" ]]; then
    exec "$REAL" "$@"
  fi
fi

# Last resort: python -m from the repo
if [[ -x "${REPO}/.venv/bin/python" ]]; then
  exec "${REPO}/.venv/bin/python" -m soundsbored "$@"
fi

echo "soundsbored: package not found." >&2
echo "  Install (Arch):" >&2
echo "    cd ${REPO} && python3 -m venv .venv && .venv/bin/pip install -e '.[download]'" >&2
echo "  Or set SOUNDSBORED_REPO to your clone path." >&2
exit 1
