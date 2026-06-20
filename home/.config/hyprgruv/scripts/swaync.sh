#!/usr/bin/env bash
# SwayNC helpers — mirrors dunst.sh / dunstctl for keybinds and waybar.

set -euo pipefail

swaync_client() {
    if command -v swaync-client >/dev/null 2>&1; then
        command -v swaync-client
        return
    fi
    if [[ -x "$HOME/.local/swaync-root/usr/bin/swaync-client" ]]; then
        echo "$HOME/.local/swaync-root/usr/bin/swaync-client"
        return
    fi
    echo "swaync-client not found" >&2
    return 1
}

CLIENT="$(swaync_client)"

show_last_missed() {
    # Control center is swaync's history UI (replaces dunst history-pop)
    "$CLIENT" -op -sw 2>/dev/null || notify-send -t 2000 "SwayNC" "Notification center unavailable"
}

show_missed_menu() {
    # Same panel — swaync groups history with a searchable UI built in
    "$CLIENT" -t -sw 2>/dev/null || notify-send -t 2000 "SwayNC" "Notification center unavailable"
}

is_paused() {
    [[ "$("$CLIENT" -D -sw 2>/dev/null || echo false)" == "true" ]]
}

toggle_paused() {
    "$CLIENT" -d -sw >/dev/null 2>&1 || true
}

close_all() {
    "$CLIENT" -C -sw >/dev/null 2>&1 || true
}

render_for_waybar() {
    local icon tooltip class

    if is_paused; then
        icon="󰂛"
        tooltip="SwayNC DND on\nLeft: open center\nRight: toggle center"
        class="paused"
    else
        icon="󰂚"
        tooltip="SwayNC\nLeft: open notification center\nRight: toggle center"
        class=""
    fi

    if [[ -n "$class" ]]; then
        printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$icon" "$tooltip" "$class"
    else
        printf '{"text":"%s","tooltip":"%s"}\n' "$icon" "$tooltip"
    fi
}

case "${1:-}" in
    last|pop|1|left)
        show_last_missed
        ;;
    menu|10|last10|right|3)
        show_missed_menu
        ;;
    toggle-pause|toggle|dnd)
        toggle_paused
        ;;
    close-all|close)
        close_all
        ;;
    *)
        render_for_waybar
        ;;
esac