#!/usr/bin/env bash
# hyprpm.sh — add/enable Hyprland plugins
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

display_header "Hyprpm Plugins"

# Ensure hyprpm exists
if ! command -v hyprpm >/dev/null 2>&1; then
  log_error "hyprpm not found. Ensure Hyprland/hyprpm is installed and on PATH."
  exit 1
fi

# Add plugin repos (idempotent)
log_status "Adding plugin repositories"
hyprpm add https://github.com/hyprwm/hyprland-plugins || true    # hyprwm
sleep 0.2
hyprpm add https://github.com/alexhulbert/Hyprchroma || true     # hyprchroma
sleep 0.2
hyprpm add https://github.com/DreamMaoMao/hycov || true          # hycov
sleep 0.2

# Enable specific plugins (idempotent)
log_status "Enabling plugins"
hyprpm enable hyprchroma || true
hyprpm enable hycov || true
sleep 0.2

# Update plugins
log_status "Updating hyprpm plugins"
if command -v lsd-print >/dev/null 2>&1; then
  hyprpm update | lsd-print
else
  hyprpm update
fi

log_success "Hyprpm plugins configured"


