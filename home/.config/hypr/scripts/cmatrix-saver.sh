#!/usr/bin/env bash
#
# cmatrix-saver.sh - F5 toggle for fullscreen cmatrix "screensaver"
# Launches exactly like "kitty -e cmatrix" but fullscreen on the focused monitor.
# Press F5 again to kill it (anywhere).
#
# This keeps it dead simple while giving the per-monitor launch behavior you wanted.
#

set -euo pipefail

CLASS="cmatrix-full"
TITLE="cmatrix-full"

# Is there already a fullscreen cmatrix running?
if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    # Kill it (use PIDs because closewindow can be unreliable on fullscreen kitty)
    mapfile -t PIDS < <(hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .pid')
    for pid in "${PIDS[@]}"; do
        [[ -n "${pid:-}" ]] && kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 0.2
    for pid in "${PIDS[@]}"; do
        if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
    notify-send "󰄛 Matrix" "Screensaver stopped" -t 1000
    exit 0
fi

# Get the monitor we were called on (so we can force focus to it before fullscreening)
MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused==true) | .name')

# Launch on the currently focused monitor.
hyprctl dispatch exec "kitty --class '$CLASS' --title '$TITLE' -e cmatrix -a -b" >/dev/null 2>&1 || true

# Wait for the window to actually register (poll every 100ms, max ~5 seconds)
for _ in {1..50}; do
    if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# Extra moment for the terminal to finish its first paint / size negotiation
sleep 0.5

# Force focus to the exact monitor the user pressed F5 on, then the window, float it, and fullscreen
hyprctl dispatch focusmonitor "$MONITOR" >/dev/null 2>&1 || true
hyprctl dispatch focuswindow "class:$CLASS" >/dev/null 2>&1 || true
hyprctl dispatch togglefloating >/dev/null 2>&1 || true

# fullscreenstate 0 2 = proper "fullscreen on this monitor only" (more reliable than plain fullscreen on multi-monitor + scaling)
hyprctl dispatch fullscreenstate 0 2 >/dev/null 2>&1 || true

# Belt + suspenders: plain fullscreen + one more fullscreenstate after a tick
sleep 0.2
hyprctl dispatch fullscreen 1 >/dev/null 2>&1 || true
hyprctl dispatch fullscreenstate 0 2 >/dev/null 2>&1 || true

notify-send "󰄛 Matrix" "Fullscreen on $MONITOR • F5 to exit" -t 1200
