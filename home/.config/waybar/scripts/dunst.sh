#!/usr/bin/env bash
# Waybar Dunst bell module
# Persistent bell icon inside the last media pill.
#
# Left click  → dunstctl history-pop   (re-shows the most recent notification)
# Right click → rofi menu of the last ~10 notifications (selection re-shows it)
#
# Icons: 󰂚 (normal), 󰂛 (paused / Do Not Disturb)
# Requires: dunst, jq, rofi

set -euo pipefail

# Choose your preferred menu launcher (rofi is already heavily used in this config)
MENU_CMD=(rofi -dmenu -i -config "$HOME/.config/rofi/config-compact.rasi" -p "Notifications" -lines 12 -width 60)

is_paused() {
    dunstctl is-paused 2>/dev/null | grep -q "true"
}

show_last_notification() {
    # Re-displays the most recent item from dunst history as a notification
    dunstctl history-pop >/dev/null 2>&1 || true
}

show_history_menu() {
    # Grab the last 10 notifications from dunst history (newest first)
    local history
    history=$(dunstctl history 2>/dev/null | jq -r '
        .data[0] // [] |
        .[0:10] |
        .[] |
        "\(.appname.data // "App") — \(.summary.data // "")\t\(.body.data // "")" ' 2>/dev/null || echo "")

    if [[ -z "$history" ]]; then
        notify-send "Dunst" "No notification history yet" -t 2000
        return
    fi

    # Let the user pick one
    local chosen
    chosen=$(printf '%s\n' "$history" | "${MENU_CMD[@]}") || return 0

    if [[ -n "$chosen" ]]; then
        dunstctl history-pop >/dev/null 2>&1 || true
    fi
}

render_for_waybar() {
    local icon tooltip class

    if is_paused; then
        icon="󰂛"
        tooltip="Dunst paused (Do Not Disturb)\nLeft: show last\nRight: history"
        class="paused"
    else
        icon="󰂚"
        tooltip="Notifications\nLeft: show last notification\nRight: list last 10"
        class=""
    fi

    if [[ -n "$class" ]]; then
        printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$icon" "$tooltip" "$class"
    else
        printf '{"text":"%s","tooltip":"%s"}\n' "$icon" "$tooltip"
    fi
}

main() {
    case "${1:-}" in
        left|1)
            show_last_notification
            ;;
        right|3)
            show_history_menu
            ;;
        *)
            render_for_waybar
            ;;
    esac
}

main "$@"