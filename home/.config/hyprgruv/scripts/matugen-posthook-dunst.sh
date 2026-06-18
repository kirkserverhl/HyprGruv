#!/usr/bin/env bash
# matugen-posthook-dunst.sh — reload dunst after dunstrc is regenerated

set -euo pipefail

killall dunst 2>/dev/null || true
dunst &>/dev/null &
disown 2>/dev/null || true