#!/usr/bin/env bash
# Cleanly dismiss the idle cmatrix overlay if it's currently running.
# Does nothing if no screensaver is active.

CLASS="cmatrix-full"

if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    ~/.config/hypr/scripts/cmatrix-saver.sh
fi
