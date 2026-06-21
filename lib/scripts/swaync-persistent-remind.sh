#!/usr/bin/env bash
# Shared helpers for sticky SwayNC reminders (critical urgency = click to dismiss).
#
# Before sourcing, set:
#   PERSISTENT_NOTIFY_ID_FILE — path to store the notification id
#   PERSISTENT_NOTIFY_APP_NAME — notify-send app name (default: Hyprgruv)

persistent_notify_init() {
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
    mkdir -p "$state_dir"
    PERSISTENT_NOTIFY_SCRIPTS="${HOME}/.config/hyprgruv/scripts"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
    : "${PERSISTENT_NOTIFY_APP_NAME:=Hyprgruv}"
}

persistent_notifications_available() {
    [[ "$(gdbus call --session \
        --dest org.freedesktop.DBus \
        --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.NameHasOwner \
        org.freedesktop.Notifications 2>/dev/null || echo "(false,)")" == "(true,)" ]]
}

persistent_ensure_notification_daemon() {
    persistent_notifications_available && return 0

    if [[ -x "${PERSISTENT_NOTIFY_SCRIPTS}/notify-autostart.sh" ]]; then
        "${PERSISTENT_NOTIFY_SCRIPTS}/notify-autostart.sh" || true
    fi

    local attempt
    for attempt in $(seq 1 20); do
        persistent_notifications_available && return 0
        sleep 0.25
    done

    return 1
}

persistent_close_notification() {
    local id
    [[ -n "${PERSISTENT_NOTIFY_ID_FILE:-}" ]] || return 0
    [[ -f "$PERSISTENT_NOTIFY_ID_FILE" ]] || return 0
    id="$(<"$PERSISTENT_NOTIFY_ID_FILE")"
    [[ -n "$id" ]] || return 0

    gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification \
        "uint32 $id" &>/dev/null || true
    rm -f "$PERSISTENT_NOTIFY_ID_FILE"
}

persistent_send_notification() {
    local title="$1"
    local body="$2"
    local icon="${3:-system-software-update}"
    local replace_args=()
    local new_id

    [[ -n "${PERSISTENT_NOTIFY_ID_FILE:-}" ]] || {
        echo "[WARNING] PERSISTENT_NOTIFY_ID_FILE is not set" >&2
        return 1
    }

    persistent_ensure_notification_daemon || {
        echo "[WARNING] SwayNC unavailable — is Hyprland running?" >&2
        return 1
    }

    if [[ -f "$PERSISTENT_NOTIFY_ID_FILE" ]]; then
        replace_args=(-r "$(<"$PERSISTENT_NOTIFY_ID_FILE")")
    fi

    if ! new_id="$(
        notify-send \
            -u critical \
            -a "$PERSISTENT_NOTIFY_APP_NAME" \
            -i "$icon" \
            -c "im.resident;reminder" \
            -h "int:expire-timeout:0" \
            -p \
            "${replace_args[@]}" \
            "$title" \
            "$body" 2>&1
    )"; then
        echo "[WARNING] notify-send failed: $new_id" >&2
        return 1
    fi

    printf '%s\n' "$new_id" >"$PERSISTENT_NOTIFY_ID_FILE"
}