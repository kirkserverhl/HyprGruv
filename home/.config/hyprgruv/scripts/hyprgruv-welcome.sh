#!/usr/bin/env bash
# First-login welcome: package sync in background → HyprGruv Settings (rofi) immediately.
# Skipped when the user checks "Don't show welcome on startup" in settings.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
DISABLE_FILE="$STATE_DIR/welcome-disabled"
LOCK_FILE="$STATE_DIR/welcome.lock"
LOG_FILE="$STATE_DIR/welcome-sync.log"
HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
SETTINGS_SCRIPT="$HOME/.config/hyprgruv/scripts/hyprgruv-settings.sh"
SYNC_SCRIPT="$HYPRGRUV_DIR/sync-packages.sh"

mkdir -p "$STATE_DIR"

[[ -f "$DISABLE_FILE" ]] && exit 0

# One welcome flow per Hyprland session
if [[ -f "$LOCK_FILE" ]]; then
    lock_pid=$(<"$LOCK_FILE" 2>/dev/null || true)
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ >"$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

sync_cmd() {
    if [[ -f "$SYNC_SCRIPT" ]]; then
        printf '%q ' bash "$SYNC_SCRIPT" sync --yes --background
    elif [[ -f "$HYPRGRUV_DIR/lib/scripts/sync-packages.sh" ]]; then
        printf '%q ' bash "$HYPRGRUV_DIR/lib/scripts/sync-packages.sh" sync --yes --background
    else
        return 1
    fi
}

start_package_sync_background() {
    local cmd
    if ! cmd="$(sync_cmd)"; then
        notify-send -u critical "HyprGruv Welcome" "Package sync script not found"
        return 1
    fi

    # Prime sudo in this shell so the background worker can install without a TTY.
    if ! sudo -n true 2>/dev/null; then
        notify-send -a "HyprGruv" "Package sync" \
            "Enter your password if prompted — sync continues in the background."
        if ! sudo -v; then
            notify-send -u normal "HyprGruv Welcome" \
                "Package sync skipped (sudo required). Use System → Packages Sync later."
            return 1
        fi
    fi

    {
        echo "=== $(date -Iseconds) welcome sync ==="
        eval "$cmd"
    } >>"$LOG_FILE" 2>&1 &
    disown

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "HyprGruv" -i "system-software-update" \
            "Welcome to HyprGruv" \
            "Opening Settings — package sync running in the background."
    fi
}

start_package_sync_background || true

export HYPRGRUV_SETTINGS_WELCOME=1
exec bash "$SETTINGS_SCRIPT" --welcome