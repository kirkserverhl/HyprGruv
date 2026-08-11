#!/usr/bin/env bash
# Focus a Hyprland workspace via 0.55+ Lua dispatchers.
# Usage: hypr-ws.sh <id|e+1|e-1|r+1|empty|...>
set -euo pipefail

target="${1:?workspace target required}"

if [[ "$target" =~ ^[0-9]+$ ]]; then
	hyprctl dispatch "hl.dsp.focus({ workspace = ${target} })"
else
	hyprctl dispatch "hl.dsp.focus({ workspace = \"${target}\" })"
fi
