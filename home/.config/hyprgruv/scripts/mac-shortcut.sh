#!/bin/bash
# Minimal Mac Cmd bridge (lowest-priority layer). Sends Ctrl+* to the focused app.
# Super+C/V/X/Z/A and Super+Shift+B/I/K in Hyprland map here.
# Press Ctrl directly anytime — this is additive, not required.

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
    hyprctl dispatch "hl.dsp.send_shortcut({mods=\"${mods}\",key=\"${key}\",window=\"activewindow\"})"
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
    select-all|a)
        send_shortcut "CTRL" "A"
        ;;
    bold|b)
        send_shortcut "CTRL" "B"
        ;;
    italic|i)
        send_shortcut "CTRL" "I"
        ;;
    link|k)
        send_shortcut "CTRL" "K"
        ;;
    *)
        echo "Unknown mac-shortcut action: $action" >&2
        echo "Known: copy|c paste|v cut|x undo|z select-all|a bold|b italic|i link|k" >&2
        exit 1
        ;;
esac