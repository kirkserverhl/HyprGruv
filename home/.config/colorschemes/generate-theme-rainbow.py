#!/usr/bin/env python3
"""Generate per-theme spectrum.json + starship-rainbow.toml from palette.json.

Optional: sync palette.json base16 from ~/.themes/*.yaml first (--sync-yaml).

Usage:
  generate-theme-rainbow.py gruvbox-dark
  generate-theme-rainbow.py --all
  generate-theme-rainbow.py --all --sync-yaml
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path
from typing import Any

HOME = Path.home()
COLORSCHEMES = HOME / ".config/colorschemes"
THEMES_DIR = HOME / ".themes"
ACTIVE_THEMES = COLORSCHEMES / "active-themes"
TEMPLATE_THEME = "gruvbox-dark"

_SPECTRUM_PATH = HOME / ".config/hyprgruv/scripts/spectrum.py"
_spec = importlib.util.spec_from_file_location("spectrum", _SPECTRUM_PATH)
spectrum = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(spectrum)

# Theme id → base16 yaml in ~/.themes (for --sync-yaml)
YAML_MAP: dict[str, str] = {
    "gruvbox-dark": "gruvbox-dark-hard.yaml",
    "catppuccin": "catppuccin-mocha.yaml",
    "nord-darker": "nord.yaml",
    "everforest-dark": "everforest-dark-hard.yaml",
    "noir": "grayscale-dark.yaml",
    "e-ink": "grayscale-dark.yaml",
    "coast-gruv": "gruvbox-dark-hard.yaml",
    "forest-night": "everforest-dark-hard.yaml",
    "ink-minimal": "grayscale-dark.yaml",
    "warm-stone": "gruvbox-dark-medium.yaml",
}

# inherit spectrum slot mapping from another theme
INHERIT: dict[str, str] = {
    "coast-gruv": "gruvbox-dark",
    "warm-stone": "gruvbox-dark",
    "forest-night": "everforest-dark",
    "ink-minimal": "e-ink",
}

RAINBOW_ORDER = [
    "color_orange",
    "color_yellow",
    "color_aqua",
    "color_blue",
    "color_bg3",
    "color_bg1",
]

# Per-theme semantic rainbow slot → base16 key (before overrides)
SPECTRUM_SLOTS: dict[str, dict[str, str]] = {
    "gruvbox-dark": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0e",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
    "catppuccin": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0e",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
    "nord-darker": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0d",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
    "everforest-dark": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0e",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
    "noir": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0e",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
    "e-ink": {
        "color_fg0": "base05",
        "color_bg1": "base02",
        "color_bg3": "base07",
        "color_orange": "base0f",
        "color_yellow": "base0a",
        "color_aqua": "base0c",
        "color_blue": "base0e",
        "color_on_orange": "base05",
        "color_on_yellow": "base05",
        "color_on_aqua": "base05",
        "color_on_blue": "base05",
        "color_green": "base0b",
        "color_red": "base08",
        "color_purple": "base09",
    },
}

SPECTRUM_OVERRIDES: dict[str, dict[str, str]] = {
    "gruvbox-dark": {
        "color_fg0": "#fbf1c7",
        "color_on_orange": "#fbf1c7",
        "color_on_yellow": "#fbf1c7",
        "color_on_aqua": "#fbf1c7",
        "color_on_blue": "#fbf1c7",
    },
}

SEGMENT_FG: dict[str, dict[str, str]] = {
    "gruvbox-dark": {"color_bg3": "#83a598"},
    "catppuccin": {"color_bg3": "#94e2d5"},
    "nord-darker": {"color_bg3": "#8fbcbb"},
    "everforest-dark": {"color_bg3": "#83c092"},
    "forest-night": {"color_bg3": "#83c092"},
    "noir": {"color_bg3": "#b9bdc2"},
    "e-ink": {"color_bg3": "#bcbcbc"},
    "ink-minimal": {"color_bg3": "#bcbcbc"},
    "coast-gruv": {"color_bg3": "#83a598"},
    "warm-stone": {"color_bg3": "#83a598"},
}

HYPRBARS: dict[str, dict[str, str]] = {
    "close": "color_orange",
    "minimize": "color_yellow",
    "maximize": "color_blue",
    "close_fg": "color_on_orange",
    "minimize_fg": "color_on_yellow",
    "maximize_fg": "color_fg0",
}


def palette_name(theme: str) -> str:
    return theme.replace("-", "_")


def load_active_themes() -> list[str]:
    if not ACTIVE_THEMES.is_file():
        return [TEMPLATE_THEME]
    out: list[str] = []
    for line in ACTIVE_THEMES.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            out.append(line)
    return out or [TEMPLATE_THEME]


def parse_yaml_palette(path: Path) -> dict[str, str]:
    slots: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^base([0-9A-Fa-f]{2}):\s*\"?([0-9a-fA-F]{6})\"?", line.strip())
        if match:
            slots[f"base{match.group(1).lower()}"] = f"#{match.group(2).lower()}"
    return slots


def sync_palette_from_yaml(theme: str) -> bool:
    yaml_name = YAML_MAP.get(theme)
    if not yaml_name:
        return False
    yaml_path = THEMES_DIR / yaml_name
    if not yaml_path.is_file():
        print(f"  skip yaml sync: missing {yaml_path}", file=sys.stderr)
        return False

    base16 = parse_yaml_palette(yaml_path)
    if len(base16) < 8:
        print(f"  skip yaml sync: no base16 in {yaml_path}", file=sys.stderr)
        return False

    # Keep existing theme-tuned palette when present (noir, e-ink, catppuccin css exports).
    palette_path = COLORSCHEMES / theme / "palette.json"
    if palette_path.is_file():
        data = json.loads(palette_path.read_text(encoding="utf-8"))
        if data.get("source") not in ("exported-from-css", "seed", "seed-gruvbox-dark"):
            return False
        # Personal seeds keep parent palette; only refresh if yaml is the canonical source.
        if theme in INHERIT and data.get("source", "").startswith("seed"):
            return False

    payload = {
        "version": 1,
        "theme": theme,
        "source": f"yaml:{yaml_name}",
        "base16": base16,
    }
    palette_path.parent.mkdir(parents=True, exist_ok=True)
    palette_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return True


def load_palette(theme: str) -> dict[str, str]:
    path = COLORSCHEMES / theme / "palette.json"
    if not path.is_file():
        raise FileNotFoundError(f"Missing palette: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    base16 = data.get("base16") or {}
    out: dict[str, str] = {}
    for slot, val in base16.items():
        if isinstance(val, str) and val.startswith("#"):
            out[slot.lower()] = val.lower()
    if len(out) < 8:
        raise ValueError(f"palette.json for {theme} has too few base16 slots")
    return out


def spectrum_config_for(theme: str) -> dict[str, Any]:
    base_theme = INHERIT.get(theme, theme)
    slots = dict(SPECTRUM_SLOTS.get(base_theme, SPECTRUM_SLOTS["gruvbox-dark"]))
    overrides = dict(SPECTRUM_OVERRIDES.get(base_theme, {}))
    if theme in SPECTRUM_OVERRIDES:
        overrides.update(SPECTRUM_OVERRIDES[theme])
    segment_fg = dict(SEGMENT_FG.get(theme, SEGMENT_FG.get(base_theme, {})))

    return {
        "version": 1,
        "description": f"{theme} semantic rainbow — orange → yellow → aqua → blue → grey → dark grey",
        "mode": "semantic",
        "starship": "starship-rainbow.toml",
        "order": list(RAINBOW_ORDER),
        "slots": slots,
        "overrides": overrides,
        "segment_fg": segment_fg,
        "hyprbars": dict(HYPRBARS),
    }


def write_spectrum_json(theme: str, cfg: dict[str, Any]) -> Path:
    out = COLORSCHEMES / theme / "spectrum.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
    return out


def build_starship_toml(theme: str, resolved: dict[str, str], segment_fg: dict[str, str]) -> str:
    template_path = COLORSCHEMES / TEMPLATE_THEME / "starship-rainbow.toml"
    if not template_path.is_file():
        raise FileNotFoundError(f"Missing template: {template_path}")
    text = template_path.read_text(encoding="utf-8")

    pname = palette_name(theme)
    text = re.sub(r"palette = '[^']+'", f"palette = '{pname}'", text, count=1)
    text = re.sub(
        r"\[palettes\.[^\]]+\][^\[]*",
        spectrum.spectrum_starship_palette(resolved, pname),
        text,
        count=1,
    )

    bg3_fg = segment_fg.get("color_bg3", resolved.get("color_aqua", "#888888"))
    text = re.sub(r"fg:#[0-9a-fA-F]{6} bg:color_bg3", f"fg:{bg3_fg} bg:color_bg3", text)
    return text


def write_starship_toml(theme: str, text: str) -> Path:
    out = COLORSCHEMES / theme / "starship-rainbow.toml"
    out.write_text(text, encoding="utf-8")
    return out


def generate_theme(theme: str, *, sync_yaml: bool = False) -> None:
    if sync_yaml:
        sync_palette_from_yaml(theme)

    palette = load_palette(theme)
    cfg = spectrum_config_for(theme)
    write_spectrum_json(theme, cfg)

    resolved = spectrum.resolve_spectrum(palette, theme)
    toml = build_starship_toml(theme, resolved, cfg.get("segment_fg") or {})
    write_starship_toml(theme, toml)

    print(f"  {theme}: spectrum + starship ({palette_name(theme)})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("themes", nargs="*", help="Theme ids (default: --all)")
    parser.add_argument("--all", action="store_true", help="All active-themes")
    parser.add_argument("--sync-yaml", action="store_true", help="Refresh palette.json from ~/.themes yaml")
    args = parser.parse_args()

    if args.all or not args.themes:
        themes = load_active_themes()
    else:
        themes = args.themes

    print(f"Generating rainbow assets for {len(themes)} theme(s)...")
    errors = 0
    for theme in themes:
        try:
            generate_theme(theme, sync_yaml=args.sync_yaml)
        except (OSError, ValueError, FileNotFoundError) as exc:
            print(f"  {theme}: FAILED — {exc}", file=sys.stderr)
            errors += 1

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())