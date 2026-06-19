#!/usr/bin/env bash
# Save a base16 palette into a theme slot (single source of truth for that theme).
#
# Usage:
#   save-theme-palette.sh <theme-id> [palette.json]
#   save-theme-palette.sh gruvbox-dark                    # uses ~/.config/matugen/user-palette.json
#   save-theme-palette.sh coast-gruv /path/to/palette.json

set -euo pipefail

THEME="${1:-}"
SRC="${2:-$HOME/.config/matugen/user-palette.json}"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
OUT="$THEME_DIR/palette.json"

if [[ -z "$THEME" ]]; then
    echo "Usage: save-theme-palette.sh <theme-id> [palette.json]" >&2
    exit 1
fi

if [[ ! -d "$THEME_DIR" ]]; then
    echo "Theme directory missing: $THEME_DIR" >&2
    echo "Run: init-theme-slot.sh $THEME" >&2
    exit 1
fi

if [[ ! -f "$SRC" ]]; then
    echo "Palette file not found: $SRC" >&2
    exit 1
fi

python3 - "$SRC" "$OUT" "$THEME" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

src, out, theme = sys.argv[1:4]
data = json.loads(Path(src).read_text(encoding="utf-8"))
base16 = data.get("base16") or {}
if not base16:
    raise SystemExit("palette source has no base16 block")

clean = {}
for slot, val in base16.items():
    if isinstance(val, str) and val.startswith("#"):
        clean[slot.lower()] = val
    elif isinstance(val, dict):
        for mode in ("dark", "default", "light"):
            node = val.get(mode) or {}
            hx = node.get("hex") or node.get("color")
            if isinstance(hx, str) and hx.startswith("#"):
                clean[slot.lower()] = hx
                break

if len(clean) < 8:
    raise SystemExit("need at least 8 base16 slots")

payload = {
    "version": 1,
    "theme": theme,
    "source": data.get("source", "custom"),
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "base16": clean,
}
Path(out).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(out)
PY

echo "Saved palette → $OUT"
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a colorschemes "Palette saved" "Theme: $THEME" -t 2500
fi