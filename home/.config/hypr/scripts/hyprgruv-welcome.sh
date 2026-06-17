#!/usr/bin/env bash
# First-login (and post-install) welcome: package sync → HyprGruv Settings (rofi).
# Skipped when the user checks "Don't show welcome on startup" in settings.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
DISABLE_FILE="$STATE_DIR/welcome-disabled"
LOCK_FILE="$STATE_DIR/welcome.lock"
HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
SETTINGS_SCRIPT="$HOME/.config/hypr/scripts/hyprgruv-settings.sh"
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

run_package_sync() {
    local cmd=()
    if [[ -f "$SYNC_SCRIPT" ]]; then
        cmd=(bash "$SYNC_SCRIPT" sync)
    elif [[ -f "$HYPRGRUV_DIR/lib/scripts/sync-packages.sh" ]]; then
        cmd=(bash "$HYPRGRUV_DIR/lib/scripts/sync-packages.sh" sync)
    else
        notify-send -u critical "HyprGruv Welcome" "Package sync script not found"
        return 1
    fi

    if command -v gum >/dev/null 2>&1; then
        gum spin --spinner dot --title "Syncing HyprGruv packages…" -- "${cmd[@]}"
    else
        notify-send "HyprGruv Welcome" "Syncing packages from manifest…"
        "${cmd[@]}"
    fi
}

# Floating kitty: sync progress, then hand off to rofi settings
if [[ -z "${HYPRGRUV_WELCOME_INSIDE:-}" ]]; then
    export HYPRGRUV_WELCOME_INSIDE=1
    exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
        kitty --class dotfiles-floating \
        --title "HyprGruv Welcome" \
        --override initial_window_width=72c \
        --override initial_window_height=20c \
        -e bash "$0"
fi

printf '\e]2;HyprGruv Welcome\a' 2>/dev/null || true

source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true
command -v gum_apply_matugen_theme >/dev/null 2>&1 && gum_apply_matugen_theme 2>/dev/null || true

clear
echo ""
if command -v gum >/dev/null 2>&1; then
    gum style --border double --margin "1 2" --padding "1 2" \
        "Welcome to HyprGruv" \
        "" \
        "Syncing packages from your manifest, then opening Settings."
else
    echo "=== Welcome to HyprGruv ==="
    echo "Syncing packages, then opening Settings…"
fi
echo ""

set +e
run_package_sync
sync_exit=$?
set -e

if [[ $sync_exit -eq 0 ]]; then
    notify-send "HyprGruv Welcome" "Package sync finished"
else
    notify-send -u normal "HyprGruv Welcome" "Package sync finished with warnings (exit $sync_exit)"
fi

echo ""
if command -v gum >/dev/null 2>&1; then
    gum style --foreground 245 "Opening HyprGruv Settings…"
else
    echo "Opening HyprGruv Settings…"
fi
sleep 0.4

export HYPRGRUV_SETTINGS_WELCOME=1
bash "$SETTINGS_SCRIPT" --welcome

if [[ -f "$DISABLE_FILE" ]]; then
    msg="Welcome disabled for future logins."
else
    msg="You can open Settings any time from the Waybar gear or: hyprgruv-settings"
fi

echo ""
if command -v gum >/dev/null 2>&1; then
    gum style --margin "1 0" "$msg"
    read -rp "Press Enter to close…" _ || true
else
    echo "$msg"
    read -rp "Press Enter to close…" _ || true
fi