#!/usr/bin/env bash
# Toggle the focused window between minimized (special workspace), maximized
# (fullscreen), and normal.

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_last_normal_ws"

read -r fullscreen workspace < <(
	hyprctl -j activewindow 2>/dev/null | jq -r '[.fullscreen, .workspace.name] | @tsv'
)

if [[ "${fullscreen:-0}" != "0" ]]; then
	hyprctl dispatch fullscreen 0
	exit 0
fi

if [[ "$workspace" == special* ]]; then
	target_ws="1"
	if [[ -f "$STATE_FILE" ]]; then
		read -r target_ws < "$STATE_FILE"
	fi
	hyprctl dispatch movetoworkspace "$target_ws"
	hyprctl dispatch fullscreen 1
	exit 0
fi

curr_id="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id')"
[[ -n "$curr_id" ]] && printf '%s\n' "$curr_id" > "$STATE_FILE"
hyprctl dispatch movetoworkspacesilent special