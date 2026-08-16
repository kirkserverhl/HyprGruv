#!/usr/bin/env bash

# Respect bar mode — do not start Waybar when Hyprbars-only or hidden.
BAR_MODE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/bar_mode"
if [[ -f "$BAR_MODE_FILE" ]]; then
    _bar_mode=$(tr -d '[:space:]' <"$BAR_MODE_FILE")
    if [[ "$_bar_mode" == "hyprbars" || "$_bar_mode" == "off" ]]; then
        exit 0
    fi
fi

# Waybar launcher — respects the last layout chosen via waybar-layout-switcher (CTRL+W).
# Falls back to "subtle" if no saved layout or the saved one is invalid.
# Available themes: alchemy, subtle, ultra_minimal, velvetline, freshstart, tester,
#   tester-inverse, gruv_fix, gruv-modern_fix, gruv-blur_fix, waybar-v1_fix

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/last_layout"
LAYOUTS_DIR="$HOME/.config/waybar/themes"
WAYBAR_DIR="$HOME/.config/waybar"

chosen="subtle"
if [[ -f "$STATE_FILE" ]]; then
    saved=$(cat "$STATE_FILE")
    if [[ -f "$LAYOUTS_DIR/$saved/config.jsonc" || -f "$LAYOUTS_DIR/$saved/config" ]]; then
        chosen="$saved"
    fi
fi

waybar_config_dir="$LAYOUTS_DIR/$chosen"

cfg=""
for cf in config.jsonc config; do
  if [[ -f "$waybar_config_dir/$cf" ]]; then
    cfg="$waybar_config_dir/$cf"
    break
  fi
done
if [[ -z "$cfg" ]]; then
    echo "No config found for theme '$chosen', falling back to subtle" >&2
    cfg="$LAYOUTS_DIR/subtle/config.jsonc"
fi

# Laptop/desktop bar geometry + font-size (desktop numbers stay as they are).
if [[ -x "$WAYBAR_DIR/scripts/apply-bar-size-profile.sh" ]]; then
    "$WAYBAR_DIR/scripts/apply-bar-size-profile.sh" "$cfg" || true
fi

# Keep freshstart rainbow slots in lockstep with the active starship palette.
if [[ -x "$WAYBAR_DIR/scripts/sync-starship-colors.sh" ]]; then
    "$WAYBAR_DIR/scripts/sync-starship-colors.sh" || true
fi

css="$waybar_config_dir/style.css"
if [[ ! -f "$css" ]]; then
    echo "No style.css for theme '$chosen', falling back to freshstart style" >&2
    css="$LAYOUTS_DIR/freshstart/style.css"
fi

killall -9 waybar 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    found=0
    for f in /proc/[0-9]*/comm; do
        [[ -r "$f" && "$(<"$f")" == "waybar" ]] && found=1 && break
    done
    [[ "$found" -eq 0 ]] && break
    sleep 0.05
done
killall -9 dunst swaync 2>/dev/null || true
"$HOME/.config/hyprgruv/scripts/notify-autostart.sh" &

ln -sf "$cfg" "$WAYBAR_DIR/config.jsonc"
ln -sf "$css" "$WAYBAR_DIR/style.css"

# @import paths in style.css resolve from CWD — run inside the theme folder.
(cd "$waybar_config_dir" && waybar -c "$(basename "$cfg")" -s style.css) &