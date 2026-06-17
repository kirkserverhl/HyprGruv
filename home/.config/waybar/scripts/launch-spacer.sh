#!/usr/bin/env bash
# Top reserved-area holder for Hyprbars mode (same geometry as Waybar).

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
cfg="$WAYBAR_DIR/themes/spacer/config.jsonc"
css="$WAYBAR_DIR/themes/spacer/style.css"

killall -9 waybar 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x waybar >/dev/null || break
    sleep 0.05
done

ln -sf "$cfg" "$WAYBAR_DIR/config.jsonc"
ln -sf "$css" "$WAYBAR_DIR/style.css"

waybar -c "$cfg" -s "$css" &