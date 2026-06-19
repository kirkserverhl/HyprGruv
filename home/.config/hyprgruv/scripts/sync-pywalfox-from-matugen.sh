#!/usr/bin/env bash
# sync-pywalfox-from-matugen.sh — write ~/.cache/wal/colors.json for pywalfox from matugen cache
#
# Pywalfox reads colors.json (pywal format). The matugen template also writes this file,
# but hex mode leaves {{image}} empty — this script patches wallpaper from pending-run.

set -euo pipefail

JSON="${HOME}/.cache/matugen/current.json"
PENDING="${HOME}/.cache/matugen/pending-run.json"
OUT="${HOME}/.cache/wal/colors.json"

[[ -f "$JSON" ]] || exit 0

python3 - "$JSON" "$PENDING" "$OUT" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

json_path, pending_path, out_path = sys.argv[1:4]

def color_hex(obj, key, fallback="#888888"):
    node = obj
    for part in key.split("."):
        if not isinstance(node, dict):
            return fallback
        node = node.get(part, {})
    if isinstance(node, str):
        return node
    if isinstance(node, dict):
        for k in ("default", "dark"):
            val = node.get(k)
            if isinstance(val, dict) and "color" in val:
                return val["color"]
            if isinstance(val, dict) and "hex" in val:
                return val["hex"]
            if isinstance(val, str):
                return val
    return fallback

data = json.loads(Path(json_path).read_text(encoding="utf-8"))
base16 = data.get("base16", {})
colors = data.get("colors", {})

def slot(name, material=None):
    if name in base16:
        return color_hex({"v": base16[name]}, "v")
    if material and material in colors:
        return color_hex({"v": colors[material]}, "v")
    return "#888888"

wallpaper = data.get("image") or ""
if pending_path and Path(pending_path).is_file():
    pending = json.loads(Path(pending_path).read_text(encoding="utf-8"))
    wallpaper = pending.get("wallpaper") or wallpaper

payload = {
    "wallpaper": wallpaper,
    "alpha": "100",
    "special": {
        "background": slot("base00", "surface_container_lowest"),
        "foreground": slot("base05", "on_surface"),
        "cursor": slot("base0d", "primary"),
    },
    "colors": {
        "color0": slot("base00", "surface_container_lowest"),
        "color1": slot("base08", "error"),
        "color2": slot("base0b", "primary"),
        "color3": slot("base0a", "secondary"),
        "color4": slot("base0f", "source_color"),
        "color5": slot("base0e", "secondary_container"),
        "color6": slot("base0c", "tertiary_container"),
        "color7": slot("base05", "on_surface"),
        "color8": slot("base03", "outline_variant"),
        "color9": slot("base09", "tertiary"),
        "color10": slot("base0b", "primary"),
        "color11": slot("base0a", "secondary"),
        "color12": slot("base0f", "source_color"),
        "color13": slot("base0e", "secondary_container"),
        "color14": slot("base0c", "tertiary_container"),
        "color15": slot("base07", "surface_bright"),
    },
}

blob = json.dumps(payload, sort_keys=True, separators=(",", ":"))
payload["checksum"] = hashlib.md5(blob.encode()).hexdigest()

Path(out_path).parent.mkdir(parents=True, exist_ok=True)
Path(out_path).write_text(json.dumps(payload, indent=4) + "\n", encoding="utf-8")
PY