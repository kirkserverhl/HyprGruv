#!/usr/bin/env python3
"""Resolve the shared Starship / Waybar / Hyprbars spectrum from base16 slots."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

HOME = Path.home()
SPECTRUM_PATH = HOME / ".config/matugen/spectrum.json"
COLORSCHEMES = HOME / ".config/colorschemes"
RAINBOW_CACHE = HOME / ".cache/matugen/rainbow-palette.json"

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

SPECTRUM_KEYS = (
    "color_fg0",
    "color_bg1",
    "color_bg3",
    "color_orange",
    "color_yellow",
    "color_aqua",
    "color_blue",
    "color_on_orange",
    "color_on_yellow",
    "color_on_aqua",
    "color_on_blue",
    "color_green",
    "color_red",
    "color_purple",
)


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


def load_theme_spectrum_config(theme: str | None) -> dict[str, Any] | None:
    if not theme:
        return None
    path = COLORSCHEMES / theme / "spectrum.json"
    if not path.is_file():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else None


def _slot_hex(base16: dict[str, str], slot: str) -> str | None:
    hx = base16.get(slot.lower()) or base16.get(slot)
    if isinstance(hx, str) and hx.startswith("#"):
        return hx.lower()
    return None


def resolve_spectrum(base16: dict[str, str], theme: str | None = None) -> dict[str, str]:
    """Map spectrum keys (color_orange, …) to hex from base16 slot dict."""
    theme_cfg = load_theme_spectrum_config(theme)
    if theme_cfg:
        mapping = theme_cfg.get("slots")
        if not isinstance(mapping, dict):
            mapping = load_spectrum_map()
        else:
            merged = dict(DEFAULT_SLOTS)
            for key, val in mapping.items():
                if isinstance(key, str) and isinstance(val, str):
                    merged[key] = val.lower()
            mapping = merged

        resolved: dict[str, str] = {}
        for key, slot in mapping.items():
            hx = _slot_hex(base16, slot)
            if hx:
                resolved[key] = hx

        overrides = theme_cfg.get("overrides")
        if isinstance(overrides, dict):
            for key, hx in overrides.items():
                if isinstance(key, str) and isinstance(hx, str) and hx.startswith("#"):
                    resolved[key] = hx.lower()

        segment_fg = theme_cfg.get("segment_fg")
        if isinstance(segment_fg, dict):
            for key, hx in segment_fg.items():
                if isinstance(key, str) and isinstance(hx, str) and hx.startswith("#"):
                    resolved[f"on_{key}"] = hx.lower()

        return resolved

    mapping = load_spectrum_map()
    resolved = {}
    for key, slot in mapping.items():
        hx = _slot_hex(base16, slot)
        if hx:
            resolved[key] = hx
    return resolved


def spectrum_source_label(theme: str | None = None) -> str:
    if theme and (COLORSCHEMES / theme / "spectrum.json").is_file():
        return f"~/.config/colorschemes/{theme}/spectrum.json"
    return "~/.config/matugen/spectrum.json"


def spectrum_css_block(resolved: dict[str, str], theme: str | None = None) -> str:
    lines = [
        f"/* Shared spectrum — Starship + Waybar + Hyprbars (from {spectrum_source_label(theme)}) */",
        "/* order: orange → yellow → aqua → blue → grey → dark grey */",
    ]
    for key in SPECTRUM_KEYS:
        if key in resolved:
            lines.append(f"@define-color {key} {resolved[key]};")
    return "\n".join(lines) + "\n"


def spectrum_starship_palette(
    resolved: dict[str, str],
    palette_name: str = "matugen",
) -> str:
    lines = [f"[palettes.{palette_name}]"]
    for key in SPECTRUM_KEYS:
        if key in resolved:
            lines.append(f'{key} = "{resolved[key]}"')
    return "\n".join(lines) + "\n"


def patch_starship_toml(
    text: str,
    resolved: dict[str, str],
    palette_name: str = "matugen",
) -> str:
    """Replace the active [palettes.*] section with resolved spectrum hex values."""
    block = spectrum_starship_palette(resolved, palette_name)
    pattern = re.compile(rf"\[palettes\.{re.escape(palette_name)}\][^\[]*", re.DOTALL)
    if pattern.search(text):
        return pattern.sub(block, text, count=1)

    generic = re.compile(r"\[palettes\.[^\]]+\][^\[]*", re.DOTALL)
    if generic.search(text):
        return generic.sub(block, text, count=1)

    return text.replace(
        f"palette = '{palette_name}'",
        f"palette = '{palette_name}'\n\n{block}",
        1,
    )


def write_rainbow_cache(theme: str, resolved: dict[str, str]) -> None:
    theme_cfg = load_theme_spectrum_config(theme) or {}
    payload = {
        "version": 1,
        "theme": theme,
        "source": spectrum_source_label(theme),
        "order": theme_cfg.get("order", list(SPECTRUM_KEYS)),
        "colors": resolved,
        "hyprbars": theme_cfg.get("hyprbars", {}),
        "segment_fg": theme_cfg.get("segment_fg", {}),
    }
    RAINBOW_CACHE.parent.mkdir(parents=True, exist_ok=True)
    RAINBOW_CACHE.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def apply_starship_asset(
    theme: str,
    resolved: dict[str, str],
    base16: dict[str, str] | None = None,
) -> Path | None:
    """Install the theme starship rainbow config and refresh the active symlink."""
    theme_cfg = load_theme_spectrum_config(theme) or {}
    asset_name = theme_cfg.get("starship", "starship-rainbow.toml")
    if not isinstance(asset_name, str):
        asset_name = "starship-rainbow.toml"

    asset = COLORSCHEMES / theme / asset_name
    out_dir = HOME / ".config/starship"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_matugen = out_dir / "matugen-rainbow.toml"
    out_active = HOME / ".config/starship.toml"

    if asset.is_file():
        text = asset.read_text(encoding="utf-8")
        palette_match = re.search(r"palette\s*=\s*['\"]([^'\"]+)['\"]", text)
        palette_name = palette_match.group(1) if palette_match else "matugen"
        text = patch_starship_toml(text, resolved, palette_name)
        out_matugen.write_text(text, encoding="utf-8")
    else:
        template = HOME / ".config/matugen/templates/starship-rainbow.toml"
        if not template.is_file():
            return None
        text = template.read_text(encoding="utf-8")
        if base16:
            for slot, hx in base16.items():
                for variant in ("dark", "default", "light"):
                    text = text.replace(f"{{{{base16.{slot}.{variant}.hex}}}}", hx)
        text = patch_starship_toml(text, resolved, "matugen")
        out_matugen.write_text(text, encoding="utf-8")

    if not out_active.exists() or out_active.is_symlink():
        if out_active.exists() or out_active.is_symlink():
            out_active.unlink()
        out_active.symlink_to(out_matugen)

    return out_matugen