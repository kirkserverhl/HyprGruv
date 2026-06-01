#!/usr/bin/env bash
# Start fullscreen cmatrix if not already running (for hypridle)
# Kept for compatibility if you still use hypridle for locking only.

CLASS="cmatrix-full"

if hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null 2>&1; then
    exit 0
fi

~/.config/hypr/scripts/cmatrix-saver.sh
