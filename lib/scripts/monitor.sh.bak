#!/usr/bin/env bash
# monitor.sh — choose and link a Hyprland monitor config
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

# ------------------------------------------------------------
# Locations
# ------------------------------------------------------------
MONITOR_DIR="$HOME/.config/hypr/conf/monitors"
MONITOR_CONFIG="$HOME/.config/hypr/conf/monitor.conf"

display_header "Monitor Configuration"

# Ensure the monitors directory exists
mkdir -p "$MONITOR_DIR"

# If MONITOR_DIR is empty but a current config exists, back it up as a preset
if [[ -z "$(find "$MONITOR_DIR" -mindepth 1 -maxdepth 1 -type f 2>/dev/null)" ]]; then
  if [[ -f "$MONITOR_CONFIG" ]]; then
    cp -a "$MONITOR_CONFIG" "$MONITOR_DIR/default.conf"
    log_status "Backed up current monitor config as: $MONITOR_DIR/default.conf"
  fi
fi

# Collect available presets (filenames only)
mapfile -t PRESETS < <(find "$MONITOR_DIR" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | sort)

if (( ${#PRESETS[@]} == 0 )); then
  log_error "No monitor presets found in: $MONITOR_DIR"
  exit 1
fi

# Gum helper
_has_gum() { command -v gum >/dev/null 2>&1; }

# Choose preset (gum or fallback)
choose_preset() {
  local choice=""
  if _has_gum; then
    log_status "Select a monitor configuration:"
    # gum choose reads items as args safely
    choice="$(gum choose --height 10 "${PRESETS[@]}")" || true
  else
    echo "Select a monitor configuration:"
    local i=1
    for p in "${PRESETS[@]}"; do
      printf '  %2d) %s\n' "$i" "$p"
      ((i++))
    done
    read -rp "Enter number: " idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx>=1 && idx<=${#PRESETS[@]} )); then
      choice="${PRESETS[$((idx-1))]}"
    fi
  fi
  echo "$choice"
}

SELECTED_PRESET="$(choose_preset)"

if [[ -z "$SELECTED_PRESET" ]]; then
  log_status "No selection made. Leaving current configuration unchanged."
  exit 0
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$MONITOR_CONFIG")"

# Replace existing link/file with the new symlink
ln -sfn "$MONITOR_DIR/$SELECTED_PRESET" "$MONITOR_CONFIG"
log_success "Switched to monitor preset: $SELECTED_PRESET"
echo "Linked: $MONITOR_CONFIG -> $MONITOR_DIR/$SELECTED_PRESET"

# Optional: prompt to reload Hyprland monitors (if running)
if _has_gum && gum confirm "Reload Hyprland monitors now (hyprctl reload)?"; then
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload || log_error "hyprctl reload failed (is Hyprland running?)"
  else
    log_error "hyprctl not found; cannot reload automatically."
  fi
fi

exit 0
