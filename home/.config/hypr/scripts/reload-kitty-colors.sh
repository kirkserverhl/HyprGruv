#!/usr/bin/env bash
# reload-kitty-colors.sh — push latest matugen colors.conf into open kitty windows
#
# Kitty reads ~/.config/kitty/colors.conf (included from kitty.conf).
# SIGUSR1 reloads the config without restarting windows.

set -euo pipefail

COLORS="$HOME/.config/kitty/colors.conf"

if [[ ! -f "$COLORS" ]]; then
    echo "[reload-kitty] No $COLORS — run matugen first" >&2
    exit 0
fi

if ! pidof kitty >/dev/null 2>&1; then
    exit 0
fi

# Official kitty reload signal (all instances)
killall -SIGUSR1 kitty 2>/dev/null || true

# Remote-control fallback — bounded so wallpaper scripts never hang on this.
if command -v kitty >/dev/null 2>&1; then
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        timeout 1 kitty @ --to-owner "$pid" load-config 2>/dev/null || true
    done < <(pidof kitty 2>/dev/null || true)
fi