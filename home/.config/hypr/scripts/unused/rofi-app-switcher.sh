#!/usr/bin/env bash
# ~/.config/hypr/scripts/rofi-app-switcher.sh — macOS Cmd+Tab style for Hyprland

if [[ -z "$1" ]]; then
    # List mode: show unique apps by initialClass (most recent first)
    hyprctl clients -j | jq -r '
        .[] 
        | select(.monitor != -1 and .workspace.id >= 0)
        | "\(.initialClass) — \(.title)icon\u001f\(.initialClass)info\u001f\(.initialClass)"
    ' | sort -u
else
    # Selection mode: focus the chosen app
    CLASS="$ROFI_INFO"
    if [[ -n "$CLASS" ]]; then
        # Small delay + background so Rofi can fully close before focus command runs
        (sleep 0.08 && hyprctl dispatch focuswindow "initialclass:^$CLASS$") &
    fi
fi
