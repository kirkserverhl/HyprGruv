#!/usr/bin/env bash
# Scaffold a personal theme slot (palette.json + wallpapers dir).
# Usage: init-theme-slot.sh <theme-id> [wallpaper-folder-under-~/themed-wallpapers]

set -euo pipefail

THEME="${1:-}"
WP_FOLDER="${2:-$THEME}"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
SEED_THEME="${3:-gruvbox-dark}"

if [[ -z "$THEME" ]]; then
    echo "Usage: init-theme-slot.sh <theme-id> [dipc-folder] [seed-theme]" >&2
    exit 1
fi

mkdir -p "$THEME_DIR/wallpapers"
DIPC="$HOME/themed-wallpapers/$WP_FOLDER"
if [[ -d "$DIPC" ]]; then
    ln -sfn "$DIPC" "$THEME_DIR/wallpapers-dipc"
fi

if [[ ! -f "$THEME_DIR/palette.json" && -f "$HOME/.config/colorschemes/$SEED_THEME/palette.json" ]]; then
    cp "$HOME/.config/colorschemes/$SEED_THEME/palette.json" "$THEME_DIR/palette.json"
    python3 - "$THEME_DIR/palette.json" "$THEME" <<'PY'
import json, sys
from pathlib import Path
path, theme = sys.argv[1:3]
data = json.loads(Path(path).read_text())
data["theme"] = theme
data["source"] = "seed"
Path(path).write_text(json.dumps(data, indent=2) + "\n")
PY
fi

if [[ ! -f "$THEME_DIR/source-color" ]]; then
    cp "$HOME/.config/colorschemes/$SEED_THEME/source-color" "$THEME_DIR/source-color" 2>/dev/null || echo "#d65d0e" >"$THEME_DIR/source-color"
fi

echo "Theme slot ready: $THEME_DIR"
ls -la "$THEME_DIR"