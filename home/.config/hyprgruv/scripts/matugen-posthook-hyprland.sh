#!/usr/bin/env bash
# matugen-posthook-hyprland.sh — reload Hyprland after matugen.conf is written

set -euo pipefail

timeout 3 hyprctl reload 2>/dev/null || true