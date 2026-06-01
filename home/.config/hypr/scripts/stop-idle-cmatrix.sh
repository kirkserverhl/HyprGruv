#!/usr/bin/env bash
# Kill the cmatrix overlay (used by hypridle if you still have a lock listener)

CLASS="cmatrix-full"

if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    mapfile -t PIDS < <(hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '.[] | select(.class == $c) | .pid')
    for pid in "${PIDS[@]}"; do
        [[ -n "${pid:-}" ]] && kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 0.3
    for pid in "${PIDS[@]}"; do
        if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
fi

# hyprlock   # uncomment if you want hypridle to also lock

