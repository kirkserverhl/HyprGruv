#!/usr/bin/env bash
# Toggle hymission Mission Control (all monitors / all workspaces).
# Hyprland 0.55+ Lua config cannot use legacy `hyprctl dispatch hymission:...`.

set -euo pipefail

hyprctl eval 'hl.plugin.hymission.toggle("forceall")' >/dev/null 2>&1