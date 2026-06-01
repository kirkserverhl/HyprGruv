#!/usr/bin/env bash
#
# cmatrix-saver.sh - F5 toggle for fullscreen cmatrix "screensaver"
# Launches kitty + cmatrix directly in fullscreen on the focused monitor,
# with slightly transparent background (wallpaper shows through).
#
# - F5 to open (appears directly fullscreen)
# - F5 again to close with a smooth full-screen fade out (no corner rectangle)
# - Pressing 'q' inside cmatrix does an instant close (intentionally fast)
#
# This keeps it dead simple while giving the per-monitor launch behavior you wanted.
#

set -euo pipefail

CLASS="cmatrix-full"
TITLE="cmatrix-full"

# Slight transparency for the terminal background (0.0 = fully see-through, 1.0 = solid).
# Wallpaper will show through the dark parts of the matrix rain.
CMATRIX_BG_OPACITY="0.82"

# Is there already a fullscreen cmatrix running?
if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    # Clean fullscreen fade-out on close.
    # We stay in fullscreen and just fade the whole thing to transparent.
    # This avoids the "tiny rectangle in top-left" that happens when exiting fullscreen
    # without a previous floating geometry.
    mapfile -t ADDRESSES < <(hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .address')
    mapfile -t PIDS      < <(hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .pid')

    hyprctl dispatch focuswindow "class:$CLASS" >/dev/null 2>&1 || true

    # Fade the entire fullscreen window to transparent
    for addr in "${ADDRESSES[@]}"; do
        [[ -n "${addr:-}" ]] && hyprctl dispatch setprop "address:$addr" opacity 0.0 >/dev/null 2>&1 || true
    done

    # Let the fade animation play
    sleep 0.45

    # Now kill the processes
    for pid in "${PIDS[@]}"; do
        [[ -n "${pid:-}" ]] && kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 0.1
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
# Launch kitty directly (bypasses problematic hyprctl dispatch exec quoting in hyprlua setups).
# The rest of the script will then focus it and make it fullscreen on the right monitor.
if ! command -v kitty >/dev/null 2>&1; then
    notify-send "󰄛 Matrix" "kitty not found in PATH" -t 2000
    exit 1
fi

kitty --class "$CLASS" --title "$TITLE" \
    --override "background_opacity=${CMATRIX_BG_OPACITY}" \
    --override background_blur=0 \
    -e cmatrix -a -b >/dev/null 2>&1 &

disown 2>/dev/null || true

# Wait for the window to actually register (poll every 100ms, max ~5 seconds)
for _ in {1..50}; do
    if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# Extra moment for the terminal to finish its first paint / size negotiation
sleep 0.5

# If we never saw the window appear, something went wrong (notify the user)
if ! hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    notify-send "󰄛 Matrix" "Failed to launch (kitty or cmatrix problem?)" -t 2500
    exit 1
fi

# Reinforce fullscreen on the exact monitor the user pressed F5 on.
# The window rule already forces fullscreen=true, so it should appear directly fullscreened.
hyprctl dispatch focusmonitor "$MONITOR" >/dev/null 2>&1 || true
hyprctl dispatch focuswindow "class:$CLASS" >/dev/null 2>&1 || true

# Use fullscreenstate 0 2 for reliable "fullscreen on this specific monitor"
hyprctl dispatch fullscreenstate 0 2 >/dev/null 2>&1 || true
sleep 0.05
hyprctl dispatch fullscreenstate 0 2 >/dev/null 2>&1 || true

notify-send "󰄛 Matrix" "Fullscreen on $MONITOR • F5 to exit (q = instant)" -t 1200
