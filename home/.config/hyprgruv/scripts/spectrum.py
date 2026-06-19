#!/usr/bin/env python3
"""Resolve the shared Starship / Waybar / Hyprbars spectrum from base16 slots."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

HOME = Path.home()
SPECTRUM_PATH = HOME / ".config/matugen/spectrum.json"

DEFAULT_SLOTS = {
    "color_fg0": "base05",
    "color_bg1": "base02",
    "color_bg3": "base0e",
    "color_orange": "base0f",
    "color_yellow": "base08",
    "color_aqua": "base0b",
    "color_blue": "base0a",
    "color_on_orange": "base00",
    "color_on_yellow": "base00",
    "color_on_aqua": "base00",
    "color_on_blue": "base05",
    "color_green": "base0b",
    "color_red": "base08",
    "color_purple": "base09",
}


def load_spectrum_map() -> dict[str, str]:
    if not SPECTRUM_PATH.is_file():
        return dict(DEFAULT_SLOTS)
    data = json.loads(SPECTRUM_PATH.read_text(encoding="utf-8"))
    slots = data.get("slots")
    if not isinstance(slots, dict):
        return dict(DEFAULT_SLOTS)
    out = dict(DEFAULT_SLOTS)
    for key, val in slots.items():
        if isinstance(key, str) and isinstance(val, str):
            out[key] = val.lower()
    return out


def resolve_spectrum(base16: dict[str, str]) -> dict[str, str]:
    """Map spectrum keys (color_orange, …) to hex from base16 slot dict."""
    mapping = load_spectrum_map()
    resolved: dict[str, str] = {}
    for key, slot in mapping.items():
        hx = base16.get(slot.lower()) or base16.get(slot)
        if isinstance(hx, str) and hx.startswith("#"):
            resolved[key] = hx.lower()
    return resolved


def spectrum_css_block(resolved: dict[str, str]) -> str:
    lines = [
        "/* Shared spectrum — Starship + Waybar + Hyprbars (from ~/.config/matugen/spectrum.json) */",
    ]
    for key in (
        "color_fg0", "color_bg1", "color_bg3",
        "color_orange", "color_yellow", "color_aqua", "color_blue",
        "color_on_orange", "color_on_yellow", "color_on_aqua", "color_on_blue",
        "color_green", "color_red", "color_purple",
    ):
        if key in resolved:
            lines.append(f"@define-color {key} {resolved[key]};")
    return "\n".join(lines) + "\n"


def spectrum_starship_palette(resolved: dict[str, str]) -> str:
    lines = ["[palettes.matugen]"]
    for key in (
        "color_fg0", "color_bg1", "color_bg3",
        "color_orange", "color_yellow", "color_aqua", "color_blue",
        "color_on_orange", "color_on_yellow", "color_on_aqua",
        "color_green", "color_red", "color_purple",
    ):
        if key in resolved:
            lines.append(f'{key} = "{resolved[key]}"')
    return "\n".join(lines) + "\n"


def patch_starship_toml(text: str, resolved: dict[str, str]) -> str:
    """Replace [palettes.matugen] section with resolved spectrum hex values."""
    import re

    block = spectrum_starship_palette(resolved)
    pattern = re.compile(r"\[palettes\.matugen\][^\[]*", re.DOTALL)
    if pattern.search(text):
        return pattern.sub(block, text, count=1)
    return text.replace("palette = 'matugen'", f"palette = 'matugen'\n\n{block}", 1)