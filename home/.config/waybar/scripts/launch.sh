#!/usr/bin/env bash

# Waybar launcher — respects the last layout chosen via waybar-layout-switcher (CTRL+W).
# Falls back to "subtle" if no saved layout or the saved one is invalid.
# Available themes: alchemy, subtle, ultra_minimal, velvetline, freshstart, tester

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

css="$waybar_config_dir/style.css"
if [[ ! -f "$css" ]]; then
    echo "No style.css for theme '$chosen', falling back to freshstart style" >&2
    css="$LAYOUTS_DIR/freshstart/style.css"
fi

killall -9 waybar 2>/dev/null || true
killall -9 dunst 2>/dev/null || true

dunst &

ln -sf "$cfg" "$WAYBAR_DIR/config.jsonc"
ln -sf "$css" "$WAYBAR_DIR/style.css"

waybar -c "$cfg" -s "$css" &