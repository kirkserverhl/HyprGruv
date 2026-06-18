#!/usr/bin/env bash
#
# Dunst helpers for keybinds.
# Recalls missed notifications as short-lived popups (5 seconds).
#
# SUPER + D  → last missed notification (shows for 5s)
# ALT  + D  → menu of last 10 (each chosen one shows for 5s)

set -euo pipefail

show_last_missed() {
    local entry
    entry=$(dunstctl history 2>/dev/null | jq -r '.data[0][0] // empty' 2>/dev/null || true)

    if [[ -z "$entry" || "$entry" == "null" ]]; then
        dunstify -t 2000 "Dunst" "No notifications in history"
        return
    fi

    local app summary body icon
    app=$(echo "$entry" | jq -r '.appname.data // "Notification"')
    summary=$(echo "$entry" | jq -r '.summary.data // ""')
    body=$(echo "$entry" | jq -r '.body.data // ""')
    icon=$(echo "$entry" | jq -r '.icon.data // ""')

    # Re-emit with explicit short timeout so it goes away after 5 seconds
    dunstify -a "$app" -i "$icon" -t 5000 "$summary" "$body"
}

show_missed_menu() {
    local json
    json=$(dunstctl history 2>/dev/null || echo '{}')

    local count
    count=$(echo "$json" | jq -r '.data[0] | length' 2>/dev/null || echo 0)

    if [[ "$count" -eq 0 ]]; then
        dunstify -t 2000 "Dunst" "No notifications in history"
        return
    fi

    # Build menu lines + keep raw entries for later lookup
    local -a labels=()
    local -a entries=()

    while IFS= read -r entry; do
        local app summary
        app=$(echo "$entry" | jq -r '.appname.data // "App"')
        summary=$(echo "$entry" | jq -r '.summary.data // ""')
        labels+=("$app — $summary")
        entries+=("$entry")
    done < <(echo "$json" | jq -r '.data[0][0:10][] | @json' 2>/dev/null)

    if [[ ${#labels[@]} -eq 0 ]]; then
        dunstify -t 2000 "Dunst" "No notifications in history"
        return
    fi

    local choice
    choice=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i \
        -config ~/.config/rofi/config-compact.rasi \
        -p "Missed Notifications (5s)" \
        -lines 12 -width 70 2>/dev/null || true)

    if [[ -z "$choice" ]]; then
        return
    fi

    # Find the matching entry and re-send it with 5s timeout
    for i in "${!labels[@]}"; do
        if [[ "${labels[$i]}" == "$choice" ]]; then
            local selected="${entries[$i]}"
            local app summary body icon
            app=$(echo "$selected" | jq -r '.appname.data // "Notification"')
            summary=$(echo "$selected" | jq -r '.summary.data // ""')
            body=$(echo "$selected" | jq -r '.body.data // ""')
            icon=$(echo "$selected" | jq -r '.icon.data // ""')

            dunstify -a "$app" -i "$icon" -t 5000 "$summary" "$body"
            break
        fi
    done
}

case "${1:-last}" in
    last|pop|1)
        show_last_missed
        ;;
    menu|10|last10)
        show_missed_menu
        ;;
    *)
        echo "Usage: $(basename "$0") {last|menu}"
        exit 1
        ;;
esac
