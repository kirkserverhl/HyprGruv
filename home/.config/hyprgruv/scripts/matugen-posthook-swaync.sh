#!/usr/bin/env bash
# matugen-posthook-swaync.sh — reload swaync after style.css is regenerated

set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/notify-daemon"
[[ -f "$state" ]] && [[ "$(tr -d '[:space:]' <"$state")" != "swaync" ]] && exit 0

swaync_bin() {
    if command -v swaync-client >/dev/null 2>&1; then
        command -v swaync-client
        return
    fi
    if [[ -x "$HOME/.local/swaync-root/usr/bin/swaync-client" ]]; then
        echo "$HOME/.local/swaync-root/usr/bin/swaync-client"
        return
    fi
    return 1
}

client="$(swaync_bin)" || exit 0
"$client" -rs 2>/dev/null || {
    killall swaync 2>/dev/null || true
    if command -v swaync >/dev/null 2>&1; then
        swaync &>/dev/null &
    elif [[ -x "$HOME/.local/swaync-root/usr/bin/swaync" ]]; then
        "$HOME/.local/swaync-root/usr/bin/swaync" &>/dev/null &
    fi
    disown 2>/dev/null || true
}