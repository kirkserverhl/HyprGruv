#!/usr/bin/env bash
#
# Geometry-aware bottom hot corners for Hyprland + hymission.
# Triggers Mission Control on the outer bottom corners only.

set -u

### CONFIG ############################################################

RADIUS=24                     # tiny deliberate corner zone (pixels)
POLL_MS=90                    # cursor poll interval (ms)
COOLDOWN_MS=900               # minimum time between triggers

# "extreme" = bottom-left of leftmost monitor + bottom-right of rightmost monitor
MODE="extreme"

LOG_FILE="/tmp/hotcorners.log"
DEBUG=0
MISSION_CONTROL="$HOME/.config/hyprgruv/scripts/mission-control.sh"

### END CONFIG #########################################################

dispatch() {
    echo "[$(date +%T)] Triggering mission control (corner hit)" >> "$LOG_FILE"
    "$MISSION_CONTROL" || true
}

log() {
    [[ $DEBUG -eq 1 ]] && echo "[$(date +%T.%3N)] $*" >> "$LOG_FILE"
}

trap 'echo "[$(date +%T)] hotcorners exiting" >> "$LOG_FILE"; exit 0' SIGINT SIGTERM

echo "[$(date +%T)] Starting hotcorners (mode=$MODE, radius=$RADIUS)" >> "$LOG_FILE"

last_trigger=0
inside_corner=0
last_mon_refresh=0
mon_data=""

while true; do
    cursor=$(hyprctl cursorpos 2>/dev/null || echo "0,0")
    cx=${cursor%%,*}
    cy=${cursor##*,}
    cx=${cx// /}
    cy=${cy// /}

    now_ms=$(date +%s%3N)
    if (( now_ms - last_mon_refresh > 800 )); then
        mon_data=$(hyprctl monitors -j 2>/dev/null | jq -r '
            .[] | "\(.name):\(.x):\(.y):\(.width):\(.height):\(.y + .height)"
        ' 2>/dev/null || echo "")
        last_mon_refresh=$now_ms
        log "refreshed monitors"
    fi

    if [[ -z "$mon_data" ]]; then
        sleep 0.2
        continue
    fi

    leftmost=$(echo "$mon_data" | sort -t: -k2 -n | head -1 | cut -d: -f1)
    rightmost=$(echo "$mon_data" | sort -t: -k2 -n | tail -1 | cut -d: -f1)

    triggered=0

    while IFS=: read -r name mx my mw mh bottom_y; do
        [[ -z "$name" ]] && continue

        bl_x=$mx
        bl_y=$bottom_y
        br_x=$(( mx + mw ))
        br_y=$bottom_y

        in_bl=0
        in_br=0

        if (( cx >= bl_x && cx <= bl_x + RADIUS && cy >= bl_y - RADIUS && cy <= bl_y )); then
            in_bl=1
        fi

        if (( cx >= br_x - RADIUS && cx <= br_x && cy >= br_y - RADIUS && cy <= br_y )); then
            in_br=1
        fi

        if (( in_bl == 1 )); then
            if [[ "$MODE" == "all-bottom" || "$name" == "$leftmost" ]]; then
                if (( inside_corner == 0 )); then
                    dispatch
                    inside_corner=1
                    last_trigger=$now_ms
                    triggered=1
                fi
            fi
        fi

        if (( in_br == 1 )); then
            if [[ "$MODE" == "all-bottom" || "$name" == "$rightmost" ]]; then
                if (( inside_corner == 0 )); then
                    dispatch
                    inside_corner=1
                    last_trigger=$now_ms
                    triggered=1
                fi
            fi
        fi
    done <<< "$mon_data"

    if (( triggered == 0 )); then
        still_inside=0
        while IFS=: read -r name mx my mw mh bottom_y; do
            [[ -z "$name" ]] && continue
            bl_x=$mx
            bl_y=$bottom_y
            br_x=$(( mx + mw ))
            br_y=$bottom_y

            if [[ "$MODE" == "all-bottom" || "$name" == "$leftmost" ]]; then
                if (( cx >= bl_x && cx <= bl_x + RADIUS && cy >= bl_y - RADIUS && cy <= bl_y )); then
                    still_inside=1
                fi
            fi

            if [[ "$MODE" == "all-bottom" || "$name" == "$rightmost" ]]; then
                if (( cx >= br_x - RADIUS && cx <= br_x && cy >= br_y - RADIUS && cy <= br_y )); then
                    still_inside=1
                fi
            fi
        done <<< "$mon_data"

        if (( still_inside == 0 )); then
            inside_corner=0
        fi
    fi

    if (( now_ms - last_trigger > COOLDOWN_MS )); then
        inside_corner=0
    fi

    sleep "0.$POLL_MS"
done