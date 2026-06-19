#!/usr/bin/env python3
"""Generate matugen output files from static preset palette CSS (Gruvbox, Nord, etc.)."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path

HOME = Path.home()

_SPECTRUM_PATH = HOME / ".config/hyprgruv/scripts/spectrum.py"
_spec = importlib.util.spec_from_file_location("spectrum", _SPECTRUM_PATH)
spectrum = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(spectrum)
COLORSCHEMES = HOME / ".config/colorschemes"
WAYBAR_CUSTOM = HOME / ".config/waybar/colors/custom"
MERIDIAN_CUSTOM = HOME / "Documents/hyprcourse/meridian/.config/waybar/colors/custom"

ASSET_MAP = {
    "catppuccin": "catppuccin-mocha",
    "nord-darker": "nord",
    "noir": "monochrome",
}

ACCENT_KEY = {
    "gruvbox-dark": "orange",
    "catppuccin": "purple",
    "nord-darker": "blue",
    "everforest-dark": "green",
    "noir": "grey1",
    "e-ink": "grey0",
}


def resolve_asset(theme: str) -> str:
    return ASSET_MAP.get(theme, theme)


def find_palette_css(theme: str) -> Path:
    asset = resolve_asset(theme)
    for root in (WAYBAR_CUSTOM, MERIDIAN_CUSTOM):
        candidate = root / f"{asset}.css"
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(f"No palette CSS for theme '{theme}' (asset: {asset})")


def parse_palette(path: Path) -> dict[str, str]:
    palette: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(
            r'@define-color\s+([a-zA-Z0-9_]+)\s+(#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}));',
            line.strip(),
        )
        if match:
            palette[match.group(1)] = match.group(2).lower()
    if not palette:
        raise ValueError(f"No @define-color entries in {path}")
    return palette


SLOT_ORDER = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
    "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F",
]


def normalize_slot_keys(slots: dict[str, str]) -> dict[str, str]:
    lower = {k.lower(): v for k, v in slots.items() if isinstance(v, str)}
    return {slot: lower.get(slot.lower(), "#000000") for slot in SLOT_ORDER}


def build_slots(palette: dict[str, str], theme: str) -> dict[str, str]:
    accent = ACCENT_KEY.get(theme, "orange")
    if accent not in palette:
        accent = "yellow" if "yellow" in palette else "blue"

    def pick(*keys: str, default: str = "#000000") -> str:
        for key in keys:
            if key in palette:
                return palette[key]
        return default

    return {
        "base00": pick("bg0"),
        "base01": pick("bg1"),
        "base02": pick("bg2"),
        "base03": pick("grey2", "bg3"),
        "base04": pick("grey1", "bg4"),
        "base05": pick("fg"),
        "base06": pick("bg2", "bg3"),
        "base07": pick("bg4", "bg3"),
        "base08": pick("red"),
        "base09": pick("purple"),
        "base0A": pick("yellow"),
        "base0B": pick("green"),
        "base0C": pick("aqua"),
        "base0D": pick(accent),
        "base0E": pick("blue"),
        "base0F": pick("orange", accent),
    }


def strip_hash(color: str) -> str:
    return color.lstrip("#")


def rgba(color: str, alpha: str = "ff") -> str:
    return f"rgba({strip_hash(color)}{alpha})"


def write_waybar(slots: dict[str, str], theme: str) -> None:
    s = slots
    content = f"""/* Preset theme: {theme} — static palette (not Material You) */
@define-color base00 {s['base00']};
@define-color base01 {s['base01']};
@define-color base02 {s['base02']};
@define-color base03 {s['base03']};
@define-color base04 {s['base04']};
@define-color base05 {s['base05']};
@define-color base06 {s['base06']};
@define-color base07 {s['base07']};
@define-color base08 {s['base08']};
@define-color base09 {s['base09']};
@define-color base0A {s['base0A']};
@define-color base0B {s['base0B']};
@define-color base0C {s['base0C']};
@define-color base0D {s['base0D']};
@define-color base0E {s['base0E']};
@define-color base0F {s['base0F']};

@define-color background @base00;
@define-color foreground @base05;
@define-color primary @base0D;
@define-color on_primary @base00;
@define-color primary_container @base0C;
@define-color on_primary_container @base05;
@define-color secondary @base0E;
@define-color on_secondary @base00;
@define-color secondary_container @base02;
@define-color tertiary @base09;
@define-color on_tertiary @base00;
@define-color tertiary_container @base0A;
@define-color error @base08;
@define-color on_error @base00;
@define-color surface @base00;
@define-color on_surface @base05;
@define-color surface_variant @base01;
@define-color on_surface_variant @base04;
@define-color outline_variant @base03;
@define-color outline @base04;
@define-color muted @base03;
@define-color surface_container @base02;
@define-color surface_container_high @base01;
@define-color workspace_active @base02;
@define-color accent @base0D;
@define-color accent_fg @base00;
@define-color urgent @base08;
@define-color on_urgent @base00;

{spectrum.spectrum_css_block(spectrum.resolve_spectrum({k.lower(): v for k, v in s.items()}, theme), theme)}

@define-color error_container {s['base08']};
@define-color inverse_on_surface {s['base06']};
@define-color inverse_primary {s['base0D']};
@define-color inverse_surface {s['base05']};
@define-color on_background {s['base05']};
@define-color on_error {s['base00']};
@define-color on_error_container {s['base05']};
@define-color on_primary_fixed {s['base00']};
@define-color on_primary_fixed_variant {s['base0D']};
@define-color on_secondary {s['base00']};
@define-color on_secondary_container {s['base05']};
@define-color on_secondary_fixed {s['base00']};
@define-color on_secondary_fixed_variant {s['base0E']};
@define-color on_tertiary_container {s['base05']};
@define-color on_tertiary_fixed {s['base00']};
@define-color on_tertiary_fixed_variant {s['base09']};
@define-color primary_fixed {s['base0D']};
@define-color primary_fixed_dim {s['base0D']};
@define-color scrim #000000;
@define-color secondary_fixed {s['base0E']};
@define-color secondary_fixed_dim {s['base0C']};
@define-color shadow #000000;
@define-color source_color {s['base0F']};
@define-color surface_bright {s['base07']};
@define-color surface_container_highest {s['base03']};
@define-color surface_container_low {s['base01']};
@define-color surface_container_lowest {s['base00']};
@define-color surface_dim {s['base00']};
@define-color surface_tint {s['base0D']};
@define-color tertiary_fixed {s['base0A']};
@define-color tertiary_fixed_dim {s['base0A']};
"""
    out = HOME / ".config/waybar/colors/matugen-waybar.css"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def write_hypr(slots: dict[str, str], theme: str) -> None:
    s = slots
    lines = [
        f"# Preset theme: {theme} — static palette (not Material You)",
        "",
    ]
    for key, val in s.items():
        lines.append(f"${key} = {rgba(val)}")
    lines.extend(
        [
            "",
            f"$background = $base00",
            f"$on_background = $base05",
            f"$primary = $base0D",
            f"$on_primary = $base00",
            f"$primary_container = $base0C",
            f"$on_primary_container = $base05",
            f"$secondary = $base0E",
            f"$on_secondary = $base00",
            f"$surface = $base00",
            f"$on_surface = $base05",
            f"$surface_variant = $base01",
            f"$on_surface_variant = $base04",
            f"$surface_container = $base02",
            f"$surface_container_high = $base01",
            f"$surface_container_highest = $base03",
            f"$outline = $base04",
            f"$outline_variant = $base03",
            f"$error = $base08",
            f"$on_error = $base00",
            f"$tertiary = $base09",
            f"$on_tertiary = $base00",
            f"$source_color = $base0F",
            f"$bg = $base00",
            f"$fg = $base05",
            f"$text = $base05",
            f"$bg1 = $base02",
        ]
    )
    out = HOME / ".config/hypr/colors/custom/matugen.conf"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_nvim(slots: dict[str, str], theme: str) -> None:
    s = slots
    content = f"""-- Preset theme: {theme} — static palette (not Material You)

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — preset theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({{
  palette = {{
    base00 = "{s['base00']}",
    base01 = "{s['base01']}",
    base02 = "{s['base02']}",
    base03 = "{s['base03']}",
    base04 = "{s['base04']}",
    base05 = "{s['base05']}",
    base06 = "{s['base06']}",
    base07 = "{s['base07']}",
    base08 = "{s['base08']}",
    base09 = "{s['base09']}",
    base0A = "{s['base0A']}",
    base0B = "{s['base0B']}",
    base0C = "{s['base0C']}",
    base0D = "{s['base0D']}",
    base0E = "{s['base0E']}",
    base0F = "{s['base0F']}",
  }},
  use_cterm = false,
  plugins = {{ default = true }},
}})

vim.api.nvim_set_hl(0, "Visual", {{ bg = "{s['base02']}", fg = "{s['base05']}" }})
vim.api.nvim_set_hl(0, "Comment", {{ fg = "{s['base03']}", italic = true }})
vim.api.nvim_set_hl(0, "@comment", {{ fg = "{s['base03']}", italic = true }})
vim.api.nvim_set_hl(0, "CursorLine", {{ bg = "{s['base01']}" }})
vim.api.nvim_set_hl(0, "DiagnosticError", {{ fg = "{s['base08']}" }})
vim.api.nvim_set_hl(0, "DiagnosticWarn", {{ fg = "{s['base0A']}" }})
vim.api.nvim_set_hl(0, "DiagnosticInfo", {{ fg = "{s['base0D']}" }})
vim.api.nvim_set_hl(0, "DiagnosticHint", {{ fg = "{s['base0C']}" }})
"""
    out = HOME / ".config/nvim/lua/matugen-theme.lua"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def write_starship(slots: dict[str, str], theme: str) -> None:
    s = {k.lower(): v for k, v in slots.items()}
    resolved = spectrum.resolve_spectrum(s, theme)
    spectrum.write_rainbow_cache(theme, resolved)
    spectrum.apply_starship_asset(theme, resolved, s)


def write_rofi(slots: dict[str, str], theme: str) -> None:
    s = slots
    content = f"""* {{
    base00: {s['base00']};
    base01: {s['base01']};
    base02: {s['base02']};
    base03: {s['base03']};
    base04: {s['base04']};
    base05: {s['base05']};
    base06: {s['base06']};
    base07: {s['base07']};
    base08: {s['base08']};
    base09: {s['base09']};
    base0A: {s['base0A']};
    base0B: {s['base0B']};
    base0C: {s['base0C']};
    base0D: {s['base0D']};
    base0E: {s['base0E']};
    base0F: {s['base0F']};

    surface-alpha: {s['base00']}e6;
    entry-surface: {s['base01']}d9;
    primary-hover: {s['base0D']}26;

    primary: {s['base0D']};
    on-primary: {s['base00']};
    primary-container: {s['base0C']};
    on-primary-container: {s['base05']};
    secondary: {s['base0E']};
    on-secondary: {s['base00']};
    secondary-container: {s['base02']};
    on-secondary-container: {s['base05']};
    tertiary: {s['base09']};
    on-tertiary: {s['base00']};
    tertiary-container: {s['base0A']};
    on-tertiary-container: {s['base05']};
    error: {s['base08']};
    on-error: {s['base00']};
    surface: {s['base00']};
    on-surface: {s['base05']};
    surface-container: {s['base02']};
    surface-container-low: {s['base01']};
    surface-container-lowest: {s['base00']};
    surface-container-high: {s['base01']};
    surface-container-highest: {s['base03']};
    on-surface-variant: {s['base04']};
    outline: {s['base04']};
    outline-variant: {s['base03']};
    source-color: {s['base0F']};
}}
"""
    out = HOME / ".config/rofi/colors.rasi"
    out.write_text(content, encoding="utf-8")


def load_palette_json(theme: str) -> dict[str, str] | None:
    path = COLORSCHEMES / theme / "palette.json"
    if not path.is_file():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    base16 = data.get("base16")
    if not isinstance(base16, dict):
        return None
    slots: dict[str, str] = {}
    for slot, val in base16.items():
        if isinstance(val, str) and val.startswith("#"):
            slots[slot.lower()] = val.lower()
    return slots if len(slots) >= 8 else None


def export_palette_json(theme: str, slots: dict[str, str]) -> None:
    out = COLORSCHEMES / theme / "palette.json"
    if out.is_file():
        return
    payload = {
        "version": 1,
        "theme": theme,
        "source": "exported-from-css",
        "base16": slots,
    }
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: generate-preset-colors.py <theme-name>", file=sys.stderr)
        return 1

    theme = sys.argv[1].strip()
    slots = load_palette_json(theme)
    palette_path: Path | None = None
    if slots is None:
        palette_path = find_palette_css(theme)
        palette = parse_palette(palette_path)
        slots = build_slots(palette, theme)
        export_palette_json(theme, slots)

    slots = normalize_slot_keys(slots)

    write_waybar(slots, theme)
    write_hypr(slots, theme)
    write_nvim(slots, theme)
    write_starship(slots, theme)
    write_rofi(slots, theme)

    if palette_path is not None:
        print(f"Preset colors applied for {theme} from {palette_path.name}")
    else:
        print(f"Preset colors applied for {theme} from palette.json")
    print(f"  accent (primary): {slots['base0D']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())