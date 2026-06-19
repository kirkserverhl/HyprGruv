#!/usr/bin/env bash
# Searchable Hyprland keybind reference (parsed from Lua config)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="${HOME}/.config/rofi/config-compact.rasi"

pkill -x rofi 2>/dev/null || true

mapfile -t entries < <("$SCRIPT_DIR/parse-keybinds.py")

if ((${#entries[@]} == 0)); then
    hyprctl notify 3 3000 0 "No keybinds found in Lua config"
    exit 1
fi

selected=$(
    printf '%s\n' "${entries[@]}" |
        rofi -dmenu -i -p "⌨  " -config "${THEME}"
)

if [[ -n "${selected:-}" ]]; then
    printf '%s' "$selected" | wl-copy
    hyprctl notify 0 2500 0 "fontsize:13,Copied: $selected"
fi