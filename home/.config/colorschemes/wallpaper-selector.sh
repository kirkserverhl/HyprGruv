#!/bin/bash
# Launch the GTK wallpaper picker (waypaper-style grid + footer buttons).
# Usage: wallpaper-selector.sh <theme-name>
# Prints the chosen wallpaper path to stdout on success.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/wallpaper-picker.py" "$@"