#!/usr/bin/env bash
# Full app launcher — all installed applications
set -euo pipefail

pkill -x rofi 2>/dev/null || true

THEME="${HOME}/.config/rofi/config-launcher.rasi"

exec rofi -show drun -modi drun,run -show-icons -replace -config "${THEME}" "$@"