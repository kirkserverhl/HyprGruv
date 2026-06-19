#!/usr/bin/env bash
# reload-kitty-colors.sh — push latest matugen kitty colors into open windows
#
# Kitty reads ~/.config/kitty/colors/custom/matugen.conf (included from kitty.conf).
# Equivalent to Ctrl+Shift+F5 (load-config) in each open kitty window:
#   - SIGUSR1 reloads all instances
#   - kitty @ load-config is the remote-control fallback per PID

set -euo pipefail

COLORS="$HOME/.config/kitty/colors/custom/matugen.conf"

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