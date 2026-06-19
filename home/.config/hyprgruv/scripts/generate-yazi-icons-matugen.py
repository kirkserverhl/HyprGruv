#!/usr/bin/env python3
"""Generate Yazi [icon] rules tinted by the current matugen palette.

Maps icons-brew semantic groups (via the Gruvbox reference palette) onto
Material You roles from ~/.cache/matugen/current.json.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HOME = Path.home()
JSON_CACHE = HOME / ".cache/matugen/current.json"
BASE_ICONS = HOME / ".config/matugen/templates/yazi-icons-gruvbox.toml"
OUT_CACHE = HOME / ".cache/matugen/yazi-icons-matugen.toml"

# icons-brew.yazi Gruvbox dark reference (group -> hex)
REFERENCE_PALETTE = {
    "grey": "#928374",
    "red": "#cc241d",
    "green": "#98971a",
    "yellow": "#d79921",
    "blue": "#458588",
    "magenta": "#b16286",
    "cyan": "#689d6a",
    "bright_grey": "#a89984",
    "bright_red": "#fb4934",
    "bright_green": "#b8bb26",
    "bright_yellow": "#fabd2f",
    "bright_blue": "#83a598",
    "bright_magenta": "#d3869b",
    "bright_cyan": "#8ec07c",
}

GROUP_TO_ROLE = {
    "grey": "outline_variant",
    "red": "error",
    "green": "tertiary",
    "yellow": "secondary",
    "blue": "primary",
    "magenta": "secondary_container",
    "cyan": "tertiary_container",
    "bright_grey": "on_surface_variant",
    "bright_red": "error",
    "bright_green": "tertiary",
    "bright_yellow": "secondary",
    "bright_blue": "primary_container",
    "bright_magenta": "tertiary",
    "bright_cyan": "secondary_container",
}

FG_RE = re.compile(r'(fg\s*=\s*")(#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}))(")')


def normalize_hex(value: str) -> str:
    value = value.strip().lower()
    if not value.startswith("#"):
        value = f"#{value}"
    if len(value) == 4:
        value = "#" + "".join(ch * 2 for ch in value[1:])
    return value


def load_matugen_colors(path: Path, mode: str = "dark") -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    raw = data.get("colors", {})
    out: dict[str, str] = {}

    for name, val in raw.items():
        if not isinstance(val, dict):
            continue
        slot = val.get(mode) or val.get("default") or {}
        if not isinstance(slot, dict):
            continue
        hexval = slot.get("hex") or slot.get("color")
        if hexval:
            out[name] = normalize_hex(hexval)
    return out


def build_color_map(matugen: dict[str, str]) -> dict[str, str]:
    hex_to_group = {normalize_hex(v): k for k, v in REFERENCE_PALETTE.items()}
    fallback = matugen.get("on_surface", "#e4e1e9")
    group_to_matugen = {
        group: matugen.get(role, fallback)
        for group, role in GROUP_TO_ROLE.items()
    }
    ref_to_matugen = {
        ref_hex: group_to_matugen[group]
        for ref_hex, group in hex_to_group.items()
    }
    return ref_to_matugen


def tint_icons(base_text: str, ref_to_matugen: dict[str, str], fallback: str) -> str:
    def repl(match: re.Match[str]) -> str:
        ref = normalize_hex(match.group(2))
        tinted = ref_to_matugen.get(ref, fallback)
        return f'{match.group(1)}{tinted}{match.group(3)}'

    body = FG_RE.sub(repl, base_text)
    lines = body.splitlines()
    if lines and lines[0].startswith("# Gruvbox"):
        lines[0] = "# Matugen icon palette (semantic groups from wallpaper colors)"
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    json_path = Path(sys.argv[1]) if len(sys.argv) > 1 else JSON_CACHE
    base_path = Path(sys.argv[2]) if len(sys.argv) > 2 else BASE_ICONS
    out_path = Path(sys.argv[3]) if len(sys.argv) > 3 else OUT_CACHE

    if not json_path.is_file():
        print(f"[generate-yazi-icons] missing {json_path}", file=sys.stderr)
        return 1
    if not base_path.is_file():
        print(f"[generate-yazi-icons] missing {base_path}", file=sys.stderr)
        return 1

    matugen = load_matugen_colors(json_path)
    if not matugen:
        print("[generate-yazi-icons] no colors in JSON cache", file=sys.stderr)
        return 1

    ref_to_matugen = build_color_map(matugen)
    fallback = matugen.get("on_surface", "#e4e1e9")
    tinted = tint_icons(base_path.read_text(encoding="utf-8"), ref_to_matugen, fallback)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(tinted, encoding="utf-8")
    sys.stdout.write(tinted)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())