#!/usr/bin/env bash
# Arch / Hyprland launcher — thin wrapper around the git package.
#
# Clone location is device-specific (do not hardcode one path):
#   deploy laptop (HyprLab)  → ~/Projects/soundsbored
#   main desktop (source)    → ~/BaaS_ISO/soundsbored
# First existing .venv/bin/soundsbored wins.
# Override with: export SOUNDSBORED_REPO=/path/to/soundsbored
#
#   Linux → rofi backend
#   macOS → fzf backend (same package, same menus/clips logic)
#
# Legacy bash implementation (if you need it):
#   ~/.config/hyprgruv/scripts/soundsbored.sh.legacy
set -euo pipefail

SELF="$(readlink -f "$0" 2>/dev/null || echo "$0")"

candidates=()
if [[ -n "${SOUNDSBORED_REPO:-}" ]]; then
  candidates+=("${SOUNDSBORED_REPO}")
else
  candidates+=(
    "${HOME}/Projects/soundsbored"
    "${HOME}/BaaS_ISO/soundsbored"
  )
fi

for dir in "${candidates[@]}"; do
  if [[ -x "${dir}/.venv/bin/soundsbored" ]]; then
    export PATH="${dir}/.venv/bin:${PATH}"
    exec "${dir}/.venv/bin/soundsbored" "$@"
  fi
done

# Fallback: package on PATH that is not this wrapper
if command -v soundsbored >/dev/null 2>&1; then
  REAL="$(command -v soundsbored)"
  if [[ "$(readlink -f "$REAL" 2>/dev/null || echo "$REAL")" != "$SELF" ]]; then
    exec "$REAL" "$@"
  fi
fi

# Last resort: python -m from a candidate that at least has a venv
for dir in "${candidates[@]}"; do
  if [[ -x "${dir}/.venv/bin/python" ]]; then
    export PATH="${dir}/.venv/bin:${PATH}"
    exec "${dir}/.venv/bin/python" -m soundsbored "$@"
  fi
done

echo "soundsbored: package not found." >&2
echo "  Install (Arch):" >&2
echo "    cd ~/Projects/soundsbored && python3 -m venv .venv && .venv/bin/pip install -e '.[download]'" >&2
echo "  Or set SOUNDSBORED_REPO to your clone path." >&2
exit 1
