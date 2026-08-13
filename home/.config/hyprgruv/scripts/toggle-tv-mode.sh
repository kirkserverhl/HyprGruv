#!/usr/bin/env bash
# toggle-tv-mode.sh — flip the LG TV between desk (1080p120) and video (4K30).
#
# Usage:
#   toggle-tv-mode.sh            # toggle
#   toggle-tv-mode.sh monitor    # desk / low-lag
#   toggle-tv-mode.sh video      # 4K for watching
set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_SETTING="$SCRIPTS/read-setting.sh"
# shellcheck source=tv-mode-common.sh
source "$SCRIPTS/tv-mode-common.sh"

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
    monitor|video|4k|uhd|cinema)
        next="$(tv_mode_normalize "$arg")"
        ;;
    *)
        echo "usage: $0 [toggle|monitor|video]" >&2
        exit 2
        ;;
esac

tv_mode_write "$next"
tv_mode_spec

# Keep the TV flush to the right of whatever is currently left of it.
pos="$(hyprctl monitors -j 2>/dev/null | jq -r --arg d "$TV_DESC_MATCH" '
    [.[] | select((.description // "") | contains($d))] | first
    | if . == null then "1600x0" else "\(.x)x\(.y)" end
')"
[[ -n "$pos" && "$pos" != "null" ]] || pos="1600x0"

if ! tv_mode_eval "$TV_RES" "$pos" "$TV_SCALE" >/dev/null; then
    notify-send -u critical "TV mode" "Failed to apply ${TV_LABEL}"
    exit 1
fi

notify-send -e -u low "TV mode" "${TV_LABEL}"
hyprctl notify 1 1800 0 "TV: ${TV_LABEL}" >/dev/null 2>&1 || true
