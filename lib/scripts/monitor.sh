#!/bin/bash

# Script to configure monitors using wdisplays and save to Hyprland config in git repo

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$HYPR_DIR/home"

# Load helpers from common.sh (provides log_* and command_exists patterns)
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

# ------------------------------------------------------------
# Ensure wdisplays (GUI display configurator) is installed.
# Uses the actual binary name "wdisplays" (user query referred to it as wldisplays).
# Prefers official repo via pacman; falls back to yay for AUR if needed.
# ------------------------------------------------------------
ensure_wdisplays() {
  if command -v wdisplays >/dev/null 2>&1; then
    return 0
  fi
  log_status "wdisplays not found — installing…"
  if sudo pacman -Si wdisplays >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm wdisplays
  elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm wdisplays
  else
    log_error "wdisplays not available in pacman repos and yay is not installed."
    log_error "Please install wdisplays manually (e.g. sudo pacman -S wdisplays or yay -S wdisplays)."
    return 1
  fi
  # Re-check after attempted install
  if ! command -v wdisplays >/dev/null 2>&1; then
    log_error "Install appeared to complete but wdisplays command still not found."
    return 1
  fi
  log_success "wdisplays installed successfully."
}

ensure_wlr_randr() {
  if command -v wlr-randr >/dev/null 2>&1; then
    return 0
  fi
  log_status "wlr-randr not found — installing…"
  if sudo pacman -Si wlr-randr >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm wlr-randr
  elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm wlr-randr
  else
    log_error "wlr-randr not available in pacman repos and yay is not installed."
    log_error "Install manually: sudo pacman -S wlr-randr"
    return 1
  fi
  hash -r 2>/dev/null || true
  if ! command -v wlr-randr >/dev/null 2>&1; then
    log_error "Install appeared to complete but wlr-randr command still not found."
    return 1
  fi
  log_success "wlr-randr installed successfully."
}

ensure_wdisplays || exit 1
ensure_wlr_randr || exit 1

# Open wdisplays in floating window (assuming Hyprland rules handle floating)
wdisplays &

# Prompt user
echo "Set up displays in wdisplays GUI and apply. Press Enter when done."
read -r

# Capture wlr-randr output
output=$(wlr-randr)

# Parse and generate config
config=""
while IFS= read -r line; do
    if [[ $line =~ ^([A-Za-z0-9-]+)\ \" ]]; then
        monitor="${BASH_REMATCH[1]}"
        enabled="no"
        res=""
        pos=""
        transform="normal"
        scale="1"
        vrr="0"
    elif [[ $line =~ Enabled:\ (yes|no) ]]; then
        enabled="${BASH_REMATCH[1]}"
    elif [[ $line =~ ([0-9]+x[0-9]+)\ px,\ ([0-9.]+)\ Hz\ \(.*current ]]; then
        res="${BASH_REMATCH[1]}@${BASH_REMATCH[2]%.*}"
    elif [[ $line =~ Position:\ ([0-9]+),([0-9]+) ]]; then
        pos="${BASH_REMATCH[1]}x${BASH_REMATCH[2]}"
    elif [[ $line =~ Transform:\ (.*) ]]; then
        transform="${BASH_REMATCH[1]}"
    elif [[ $line =~ Scale:\ ([0-9.]+) ]]; then
        scale="${BASH_REMATCH[1]}"
    elif [[ $line =~ Adaptive\ Sync:\ (enabled|disabled) ]]; then
        if [[ "${BASH_REMATCH[1]}" == "enabled" ]]; then vrr="1"; fi
        if [[ "$enabled" == "yes" ]]; then
            trans_num=0
            case "$transform" in
                normal) trans_num=0 ;;
                90) trans_num=1 ;;
                180) trans_num=2 ;;
                270) trans_num=3 ;;
            esac
            config+="monitor=$monitor,$res,$pos,$scale,transform,$trans_num,vrr,$vrr\n"
        fi
    fi
done <<< "$output"

# Write to repo file
mkdir -p "$REPO_DIR/.config/hypr/conf"
echo -e "$config" > "$REPO_DIR/.config/hypr/conf/monitor.conf"

echo "Configuration saved to $REPO_DIR/.config/hypr/conf/monitor.conf"
