#!/usr/bin/env bash
# Open the full pinned pavucontrol panel (uses Hyprland window rules).
set -euo pipefail

pkill -x pavucontrol 2>/dev/null || true
sleep 0.05
pavucontrol &