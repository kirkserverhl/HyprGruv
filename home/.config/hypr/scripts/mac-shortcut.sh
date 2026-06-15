#!/bin/bash
# macOS-style (SUPER/Cmd) → Ctrl+letter translation for Wayland/Hyprland.
# Uses hyprctl sendshortcut so the shortcut is delivered to the active window
# by the compositor (more reliable than wtype or send_shortcut+repeating in Lua).
#
# Usage:
#   mac-shortcut.sh copy     # Super+C → Ctrl+C (or Ctrl+Shift+C in terminals)
#   mac-shortcut.sh paste    # Super+V → Ctrl+V (or Ctrl+Shift+V in terminals)
#   mac-shortcut.sh cut      # Super+X → Ctrl+X
#   mac-shortcut.sh undo     # Super+Z → Ctrl+Z

set -euo pipefail

action="${1:-}"

active_class() {
    hyprctl activewindow -j 2>/dev/null \
        | sed -n 's/.*"class"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n1
}

is_terminal() {
    local cls
    cls="$(active_class)"
    case "$cls" in
        kitty|ghostty|Ghostty|Alacritty|wezterm-gui|foot|com.mitchellh.ghostty|org.wezfurlong.wezterm)
            return 0
            ;;
    esac
    return 1
}

send_shortcut() {
    local mods="$1"
    local key="$2"
    hyprctl dispatch sendshortcut "${mods}, ${key},"
}

case "$action" in
    copy|c)
        if is_terminal; then
            send_shortcut "CTRL SHIFT" "C"
        else
            send_shortcut "CTRL" "C"
        fi
        ;;
    paste|v)
        if is_terminal; then
            send_shortcut "CTRL SHIFT" "V"
        else
            send_shortcut "CTRL" "V"
        fi
        ;;
    cut|x)
        send_shortcut "CTRL" "X"
        ;;
    undo|z)
        send_shortcut "CTRL" "Z"
        ;;
    i)
        send_shortcut "CTRL" "I"
        ;;
    u)
        send_shortcut "CTRL" "U"
        ;;
    k)
        send_shortcut "CTRL" "K"
        ;;
    *)
        echo "Unknown mac-shortcut action: $action" >&2
        echo "Known: copy|c, paste|v, cut|x, undo|z, i, u, k" >&2
        exit 1
        ;;
esac