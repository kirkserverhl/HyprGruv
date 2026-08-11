#!/usr/bin/env bash
# Create/focus the next free workspace for the laptop 1/2/+ model.
# Prefers lowest free id >= 3 so + yields 3,4,5… instead of jumping to 11 after 9/10.
set -euo pipefail

used="$(hyprctl workspaces -j 2>/dev/null | jq -r '[.[].id | select(. > 0)] | @csv')"
next=""
for i in $(seq 3 40); do
	if [[ -z "$used" ]] || ! grep -qw "$i" <<<"${used//,/ }"; then
		next=$i
		break
	fi
done
if [[ -z "$next" ]]; then
	max="$(hyprctl workspaces -j 2>/dev/null | jq '[.[].id | select(. > 0)] | max // 2')"
	next=$((max + 1))
fi

exec "$(dirname "$0")/hypr-ws.sh" "$next"
