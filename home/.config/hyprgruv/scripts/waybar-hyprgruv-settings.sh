#!/usr/bin/env bash
# Waybar click target for the HyprGruv Settings gear icon.
set -euo pipefail

LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings/waybar-click.log"
mkdir -p "$(dirname "$LOG")"
echo "$(date '+%F %T') waybar gear clicked (pid $$)" >>"$LOG"

# ~/scripts is reserved for the user's own scripts (not stowed by hyprgruv).
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/scripts:$PATH"

pkill -x rofi 2>/dev/null || true
exec "$HOME/.config/hyprgruv/scripts/hyprgruv-settings.sh"