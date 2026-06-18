#!/usr/bin/env bash
# cmatrix-pane.sh — decorative matrix rain; first keypress drops to a shell.
# Uses cmatrix -s (screensaver: exits on first keystroke when the pane is focused).
set -euo pipefail

if command -v cmatrix >/dev/null 2>&1; then
    cmatrix -s -C "${CMATRIX_COLOR:-green}" "$@"
fi

exec "${SHELL:-bash}" -l