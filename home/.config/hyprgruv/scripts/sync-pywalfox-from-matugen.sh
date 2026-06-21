#!/usr/bin/env bash
# sync-pywalfox-from-matugen.sh — write ~/.cache/wal/colors.json for pywalfox
#
# Pywalfox reads colors.json (pywal format). Matugen's pywalfox template also
# writes this file, but hex/preset flows may leave {{image}} empty — this script
# patches wallpaper and picks the freshest palette source (not always current.json).

set -euo pipefail

PENDING="${HOME}/.cache/matugen/pending-run.json"
OUT="${HOME}/.cache/wal/colors.json"
CURRENT_THEME_FILE="${HOME}/.config/colorschemes/.current-theme"

python3 - "$PENDING" "$OUT" "$CURRENT_THEME_FILE" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

pending_path, out_path, theme_file = sys.argv[1:4]
home = Path.home()

def read_json(path: Path):
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None

def normalize_base16(raw: dict) -> dict:
    out = {}
    if not isinstance(raw, dict):
        return out
    for key, val in raw.items():
        slot = str(key).lower()
        if not slot.startswith("base"):
            continue
        if isinstance(val, str) and val.startswith("#"):
            out[slot] = val
        elif isinstance(val, dict):
            for k in ("dark", "default"):
                node = val.get(k)
                if isinstance(node, dict):
                    color = node.get("color") or node.get("hex")
                    if isinstance(color, str) and color.startswith("#"):
                        out[slot] = color
                        break
                elif isinstance(node, str) and node.startswith("#"):
                    out[slot] = node
                    break
    return out

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

def base16_from_matugen(data: dict) -> dict:
    base16 = normalize_base16(data.get("base16") or {})
    if len(base16) >= 8:
        return base16
    colors = data.get("colors") or {}
    material_map = {
        "base00": "surface_container_lowest",
        "base01": "surface_container_low",
        "base02": "surface_container",
        "base03": "outline_variant",
        "base04": "on_surface_variant",
        "base05": "on_surface",
        "base06": "inverse_on_surface",
        "base07": "surface_bright",
        "base08": "error",
        "base09": "tertiary",
        "base0a": "secondary",
        "base0b": "primary",
        "base0c": "tertiary_container",
        "base0d": "primary",
        "base0e": "secondary_container",
        "base0f": "source_color",
    }
    out = {}
    for slot, material in material_map.items():
        hexval = color_hex({"v": colors.get(material, {})}, "v", "")
        if hexval.startswith("#"):
            out[slot] = hexval
    return out

def score_source(path: Path, data: dict, pending: dict, theme_hint: str) -> int:
    if not data:
        return -1
    base16 = data.get("base16") if "base16" in data else base16_from_matugen(data)
    if len(base16) < 8:
        return -1

    score = len(base16)
    try:
        score += int(path.stat().st_mtime)
    except OSError:
        pass

    pending_theme = (pending.get("theme") or "").strip()
    data_theme = (data.get("theme") or "").strip()
    if theme_hint and data_theme == theme_hint:
        score += 250_000
    if pending_theme and data_theme == pending_theme:
        score += 250_000

    method = (pending.get("method") or "").strip()
    if method in {"saved-config", "preset-static"} and path.name in {
        "user-palette.json", "current-palette.json"
    }:
        score += 500_000

    if path.name == "current.json" and method in {"saved-config", "preset-static"}:
        score -= 500_000

    return score

pending = read_json(Path(pending_path)) or {}
theme_hint = ""
if theme_file and Path(theme_file).is_file():
    theme_hint = Path(theme_file).read_text(encoding="utf-8").strip()

candidates = []
cache = home / ".cache/matugen"
colorschemes = home / ".config/colorschemes"

for rel in (
    cache / "current.json",
    home / ".config/matugen/user-palette.json",
    cache / "current-palette.json",
):
    data = read_json(rel)
    if data:
        candidates.append((rel, data))

if theme_hint:
    palette = colorschemes / theme_hint / "palette.json"
    data = read_json(palette)
    if data:
        candidates.append((palette, data))

if not candidates:
    sys.exit(0)

best_path, best_data = max(candidates, key=lambda item: score_source(item[0], item[1], pending, theme_hint))

base16 = best_data.get("base16") if "base16" in best_data else {}
base16 = normalize_base16(base16) or base16_from_matugen(best_data)
if len(base16) < 8:
    sys.exit(0)

colors = best_data.get("colors") or {}

def slot(name, material=None):
    if name in base16:
        return base16[name]
    if material and material in colors:
        return color_hex({"v": colors[material]}, "v")
    return "#888888"

wallpaper = best_data.get("wallpaper") or best_data.get("image") or ""
pending_wp = pending.get("wallpaper") or ""
if pending_wp:
    try:
        pending_mtime = Path(pending_path).stat().st_mtime
    except OSError:
        pending_mtime = 0
    try:
        source_mtime = best_path.stat().st_mtime
    except OSError:
        source_mtime = 0
    if pending_mtime >= source_mtime:
        wallpaper = pending_wp

if not wallpaper:
    for fallback in (
        home / ".config/matugen/user-palette.json",
        cache / "current-palette.json",
        home / ".config/last_wallpaper.txt",
        home / ".config/settings/default",
    ):
        if fallback.suffix == ".json":
            fb = read_json(fallback) or {}
            wallpaper = fb.get("wallpaper") or fb.get("image") or ""
        elif fallback.is_file():
            wallpaper = fallback.read_text(encoding="utf-8").strip()
        if wallpaper:
            break

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