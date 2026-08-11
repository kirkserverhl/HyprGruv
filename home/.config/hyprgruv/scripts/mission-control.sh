#!/usr/bin/env bash
# Toggle hymission Mission Control (all monitors / all workspaces).
# Hyprland 0.55+ Lua: use hl.plugin API (not legacy hyprctl dispatch hymission:…).
set -euo pipefail

if ! hyprctl plugin list 2>/dev/null | grep -q 'Plugin hymission'; then
    notify-send -u low "Mission Control" \
        "hymission not loaded yet. Wait a few seconds after login, or run: hyprpm reload" \
        2>/dev/null || true
    # Best-effort late load
    command -v hyprpm >/dev/null 2>&1 && hyprpm reload >/dev/null 2>&1 || true
    sleep 0.3
fi

if hyprctl eval 'if hl.plugin.hymission ~= nil then hl.plugin.hymission.toggle("forceall"); reapply_hymission() end' \
    >/dev/null 2>&1; then
    exit 0
fi

# Fallback without reapply_hymission symbol
if hyprctl eval 'if hl.plugin.hymission ~= nil then hl.plugin.hymission.toggle("forceall") end' \
    >/dev/null 2>&1; then
    exit 0
fi

notify-send -u critical "Mission Control" \
    "Could not toggle hymission. Install plugins: bash ~/.hyprgruv/lib/scripts/hyprpm.sh && hyprpm reload" \
    2>/dev/null || true
exit 1
