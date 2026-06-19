#!/usr/bin/env bash
# Login / sync helper — enforce saved bar mode without flipping it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bar-mode-common.sh
source "$SCRIPT_DIR/bar-mode-common.sh"

mkdir -p "$STATE_DIR"
rm -f "$STATE_DIR/bar_mode_guard" "$STATE_DIR/bar_mode.lock"

mode=$(read_bar_mode)

case "$mode" in
    off)
        NOTIFY=":" apply_bar_mode "off"
        ;;
    hyprbars)
        NOTIFY=":" apply_bar_mode "hyprbars"
        ;;
    waybar)
        NOTIFY=":" apply_bar_mode "waybar"
        ;;
esac