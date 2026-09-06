#!/usr/bin/env bash
# toggle-tv-mode.sh — Super+Alt+M
#
#   monitor  4-wide desk, TV 1080p120 on the right
#   video    desk panels off, TV 4K60 only (movie night — use the laptop)
#
# Usage:
#   toggle-tv-mode.sh            # toggle
#   toggle-tv-mode.sh monitor    # desk / low-lag
#   toggle-tv-mode.sh video      # movie night
set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_SETTING="$SCRIPTS/read-setting.sh"
# shellcheck source=tv-mode-common.sh
source "$SCRIPTS/tv-mode-common.sh"

if ! tv_is_desktop_profile; then
    notify-send -u low "TV mode" "Desktop profile only"
    exit 0
fi

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-tv-mode.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

arg="${1:-toggle}"
current="$(tv_mode_current)"
case "$arg" in
    toggle|"")
        if [[ "$current" == "video" ]]; then
            next="monitor"
        else
            next="video"
        fi
        ;;
    monitor|video|4k|uhd|cinema|movie)
        next="$(tv_mode_normalize "$arg")"
        ;;
    *)
        echo "usage: $0 [toggle|monitor|video]" >&2
        exit 2
        ;;
esac

if [[ "$next" == "video" ]] && ! tv_connected; then
    notify-send -u critical "TV mode" "LG TV not connected — leaving the desk on"
    exit 1
fi

tv_mode_write "$next"
tv_mode_spec

if ! "$SCRIPTS/apply-desktop-monitors.sh"; then
    notify-send -u critical "TV mode" "Failed to apply ${TV_LABEL}"
    exit 1
fi

if [[ "$next" == "video" ]]; then
    tv_focus
fi

notify-send -e -u low "TV mode" "${TV_LABEL}"
hyprctl notify 1 1800 0 "TV: ${TV_LABEL}" >/dev/null 2>&1 || true
