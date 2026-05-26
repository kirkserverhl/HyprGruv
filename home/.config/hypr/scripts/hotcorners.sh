#!/usr/bin/env bash
#
# Custom geometry-aware hot corners for Hyprland + hymission
# Triggers Mission Control when the mouse hits the real bottom-left
# or bottom-right corners of your actual monitor layout.
#
# Replaces the old cargo hyprcorners which only supported a 0,0 rectangle.
#
# Usage:
#   ./hotcorners.sh                 # run in foreground (for testing)
#   The start-hyprcorners wrapper launches this in the background.
#
# To change behavior, edit the variables below.

set -u

### CONFIG ############################################################

RADIUS=110                    # pixels from the actual corner
POLL_MS=85                    # how often to check cursor (lower = more responsive, more CPU)
COOLDOWN_MS=600               # minimum time between triggers

# Which corners to watch.
# "extreme" = bottom-left of the *leftmost* monitor + bottom-right of the *rightmost* monitor
# "all-bottom" = bottom-left AND bottom-right of *every* monitor (more zones)
MODE="extreme"                # "extreme" | "all-bottom"

LOG_FILE="/tmp/hotcorners.log"
# Set to 1 for verbose per-poll logging (noisy)
DEBUG=0

### END CONFIG #########################################################

dispatch() {
    local arg="$1"
    echo "[$(date +%T)] Dispatching hymission:toggle,$arg (mouse corner)" >> "$LOG_FILE"
    hyprctl dispatch hymission:toggle "$arg" >/dev/null 2>&1
}

log() {
    [[ $DEBUG -eq 1 ]] && echo "[$(date +%T.%3N)] $*" >> "$LOG_FILE"
}

# Graceful exit on kill
trap 'echo "[$(date +%T)] hotcorners exiting" >> "$LOG_FILE"; exit 0' SIGINT SIGTERM

echo "[$(date +%T)] Starting smart hotcorners (mode=$MODE, radius=$RADIUS)" >> "$LOG_FILE"

last_trigger=0
inside_corner=0

while true; do
    # Get current cursor position (format: "1234,567")
    cursor=$(hyprctl cursorpos 2>/dev/null || echo "0,0")
    cx=${cursor%%,*}
    cy=${cursor##*,}
    cx=${cx// /}
    cy=${cy// /}

    # Refresh monitor data every ~800ms to keep overhead low
    now_ms=$(date +%s%3N)
    if (( now_ms - ${last_mon_refresh:-0} > 800 )); then
        # Parse monitors into simple variables we can loop over
        # Each line: name:x:y:w:h:bottom_y
        mon_data=$(hyprctl monitors -j 2>/dev/null | jq -r '
            .[] | "\(.name):\(.x):\(.y):\(.width):\(.height):\(.y + .height)"
        ' 2>/dev/null || echo "")

        last_mon_refresh=$now_ms
        log "refreshed monitors"
    fi

    if [[ -z "${mon_data:-}" ]]; then
        sleep 0.2
        continue
    fi

    triggered=0

    # Iterate monitors
    while IFS=: read -r name mx my mw mh bottom_y; do
        [[ -z "$name" ]] && continue

        bl_x=$mx
        bl_y=$bottom_y
        br_x=$(( mx + mw ))
        br_y=$bottom_y

        # Bottom-left zone for this monitor
        if (( cx >= bl_x && cx <= bl_x + RADIUS && cy >= bl_y - RADIUS && cy <= bl_y )); then
            if [[ "$MODE" == "all-bottom" || "$name" == "$(echo "$mon_data" | sort -t: -k2 -n | head -1 | cut -d: -f1)" ]]; then
                # For "extreme" mode we only care about the true leftmost monitor's BL
                if [[ "$MODE" == "extreme" ]]; then
                    leftmost=$(echo "$mon_data" | sort -t: -k2 -n | head -1 | cut -d: -f1)
                    [[ "$name" != "$leftmost" ]] && continue
                fi

                if (( inside_corner == 0 )); then
                    dispatch "forceall"
                    inside_corner=1
                    last_trigger=$now_ms
                    triggered=1
                fi
            fi
        fi

        # Bottom-right zone for this monitor
        if (( cx >= br_x - RADIUS && cx <= br_x && cy >= br_y - RADIUS && cy <= br_y )); then
            if [[ "$MODE" == "all-bottom" || "$name" == "$(echo "$mon_data" | sort -t: -k2 -n | tail -1 | cut -d: -f1)" ]]; then
                if [[ "$MODE" == "extreme" ]]; then
                    rightmost=$(echo "$mon_data" | sort -t: -k2 -n | tail -1 | cut -d: -f1)
                    [[ "$name" != "$rightmost" ]] && continue
                fi

                if (( inside_corner == 0 )); then
                    dispatch "forceall"
                    inside_corner=1
                    last_trigger=$now_ms
                    triggered=1
                fi
            fi
        fi

    done <<< "$mon_data"

    # If we left all corner zones, allow future triggers
    if (( triggered == 0 )); then
        inside_corner=0
    fi

    # Cooldown safety (in case we somehow stay "inside")
    if (( now_ms - last_trigger > COOLDOWN_MS )); then
        inside_corner=0
    fi

    sleep "0.$POLL_MS"
done
