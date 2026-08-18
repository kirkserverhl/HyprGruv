#!/usr/bin/env python3
"""Prepare Super+W theme palettes and write official (tailored) app configs.

Super+W applies these official files *before* leftover matugen so starship,
kitty, neovim, waybar, swaync, and rofi never flash a generated palette.
Matugen leftover still paints hyprlock / firefox / bat / btop / Qt colors / …
"""

from __future__ import annotations

import importlib.util
import json
import os
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
    for out in (
        HOME / ".config/waybar/colors/matugen-waybar.css",
        HOME / ".config/wlogout/colors.css",
    ):
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
            # Inactive windows: theme secondary (not bland grey base01)
            f"$inactive_border = $base0E",
            f"$bg = $base00",
            f"$fg = $base05",
            f"$text = $base05",
            f"$bg1 = $base02",
        ]
    )

    hypr_root = HOME / ".config/hypr"
    if not (hypr_root / "hyprland.lua").is_file():
        repo = Path(os.environ.get("HYPR_DIR", str(HOME / ".hyprgruv"))) / "home/.config/hypr"
        if (repo / "hyprland.lua").is_file():
            hypr_root = repo
    out = hypr_root / "colors/custom/matugen.conf"
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

{_lualine_lua("auto")}
"""
    out = HOME / ".config/nvim/lua/matugen-theme.lua"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def write_starship(slots: dict[str, str], theme: str) -> None:
    """Install fixed per-theme starship (gruvbox/catppuccin/…).

    Uses the theme's seed palette only — never the Super+W source accent —
    so the prompt always matches the theme brand, not the border source color.
    """
    # Prefer canonical theme seed (no user-accent) for starship + rainbow cache
    try:
        seed = resolve_theme_slots(theme)
    except Exception:
        seed = {k.lower(): v for k, v in slots.items()}
    # Strip any baked accent from live slots if seed load failed: still use curated file
    s = {k.lower(): v for k, v in seed.items()}
    resolved = spectrum.resolve_spectrum(s, theme)
    spectrum.write_rainbow_cache(theme, resolved)
    spectrum.apply_starship_asset(theme, resolved, s)



def write_mpv(slots: dict[str, str], theme: str) -> None:
    """ModernZ OSC + mpv OSD colors from base16 (same mapping as matugen templates)."""
    s = {k.lower(): v for k, v in slots.items()}
    for key in ("base00", "base01", "base02", "base03", "base04", "base05",
                "base08", "base0a", "base0b", "base0d"):
        s.setdefault(key, {
            "base00": "#1d2021", "base01": "#282828", "base02": "#3c3836",
            "base03": "#7c6f64", "base04": "#928374", "base05": "#ebdbb2",
            "base08": "#cc241d", "base0a": "#d79921", "base0b": "#98971a",
            "base0d": "#d65d0e",
        }[key])

    mpv_dir = HOME / ".config/mpv"
    mpv_dir.mkdir(parents=True, exist_ok=True)
    (mpv_dir / "script-opts").mkdir(parents=True, exist_ok=True)

    osd = f"""# mpv OSD colors — preset {theme} (machine-local)
# Included from mpv.conf via: include=~~/mpv-matugen.conf

osd-color='{s["base05"]}'
osd-border-color='{s["base00"]}'
"""
    (mpv_dir / "mpv-matugen.conf").write_text(osd, encoding="utf-8")

    modernz = f"""# ModernZ OSC colors — preset {theme} (machine-local)
# Loaded by modernz.lua after modernz.conf

osc_color={s["base00"]}
window_title_color={s["base05"]}
window_controls_color={s["base05"]}
windowcontrols_close_hover={s["base08"]}
windowcontrols_max_hover={s["base0a"]}
windowcontrols_min_hover={s["base0b"]}
title_color={s["base05"]}
cache_info_color={s["base04"]}
time_color={s["base05"]}
chapter_title_color={s["base04"]}
seekbarfg_color={s["base0d"]}
seekbarbg_color={s["base03"]}
seekbar_cache_color={s["base02"]}
hover_effect_color={s["base0d"]}
nibble_color={s["base0d"]}
nibble_current_color={s["base05"]}
side_buttons_color={s["base05"]}
middle_buttons_color={s["base05"]}
playpause_color={s["base05"]}
held_element_color={s["base04"]}
thumbnail_border_color={s["base01"]}
thumbnail_border_outline={s["base03"]}
"""
    (mpv_dir / "script-opts/modernz-matugen.conf").write_text(modernz, encoding="utf-8")


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


CANONICAL_PALETTE_SOURCES = frozenset({
    "exported-from-css",
    "preset-static",
    "theme-seed",
})


def palette_json_path(theme: str) -> Path:
    return COLORSCHEMES / theme / "palette.json"


def palette_json_source(theme: str) -> str | None:
    path = palette_json_path(theme)
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    source = data.get("source")
    return source if isinstance(source, str) else None


def should_use_canonical_palette(theme: str) -> bool:
    """Theme switcher picks must use the fixed slot palette, not wallpaper extracts."""
    if os.environ.get("THEME_SWITCHER_APPLY") == "1":
        return True
    source = palette_json_source(theme)
    if source is None:
        return False
    return source not in CANONICAL_PALETTE_SOURCES


def load_palette_json(theme: str) -> dict[str, str] | None:
    path = palette_json_path(theme)
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


def export_palette_json(theme: str, slots: dict[str, str], *, force: bool = False) -> None:
    out = palette_json_path(theme)
    if out.is_file() and not force:
        return
    payload = {
        "version": 1,
        "theme": theme,
        "source": "exported-from-css",
        "base16": slots,
    }
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def resolve_theme_slots(theme: str) -> dict[str, str]:
    """Load fixed theme palette (canonical CSS when present, else palette.json).

    Super+W sets THEME_SWITCHER_APPLY=1 so we prefer the theme seed, not a
    wallpaper extract. Only gruvbox has a waybar CSS seed on this install —
    other themes ship palette.json only; fall back instead of crashing.
    """
    use_canonical = should_use_canonical_palette(theme)
    slots = None if use_canonical else load_palette_json(theme)
    if slots is None:
        try:
            palette_path = find_palette_css(theme)
            palette = parse_palette(palette_path)
            slots = build_slots(palette, theme)
            export_palette_json(theme, slots, force=True)
        except FileNotFoundError:
            slots = load_palette_json(theme)
            if slots is None:
                raise FileNotFoundError(
                    f"No palette CSS or palette.json for theme '{theme}'"
                ) from None
    return normalize_slot_keys(slots)



def write_kitty(slots: dict[str, str], theme: str) -> None:
    """Standard base16 kitty theme; primary/source (base0D) drives cursor/selection."""
    s = {k.lower(): v for k, v in slots.items()}
    for key, default in (
        ("base00", "#1d2021"),
        ("base01", "#282828"),
        ("base02", "#3c3836"),
        ("base03", "#665c54"),
        ("base04", "#928374"),
        ("base05", "#ebdbb2"),
        ("base06", "#fbf1c7"),
        ("base07", "#fbf1c7"),
        ("base08", "#cc241d"),
        ("base09", "#d65d0e"),
        ("base0a", "#d79921"),
        ("base0b", "#98971a"),
        ("base0c", "#689d6a"),
        ("base0d", "#d65d0e"),
        ("base0e", "#b16286"),
        ("base0f", "#d65d0e"),
    ):
        s.setdefault(key, default)

    content = f"""# Preset theme: {theme} — static base16 (source/primary = base0D)
cursor            {s["base0d"]}
cursor_text_color {s["base00"]}

foreground            {s["base05"]}
background            {s["base00"]}
selection_foreground  {s["base00"]}
selection_background  {s["base0d"]}
url_color             {s["base0c"]}

#: black
color0  {s["base00"]}
color8  {s["base03"]}
#: red
color1  {s["base08"]}
color9  {s["base08"]}
#: green
color2  {s["base0b"]}
color10 {s["base0b"]}
#: yellow
color3  {s["base0a"]}
color11 {s["base0a"]}
#: blue
color4  {s["base0e"]}
color12 {s["base0e"]}
#: magenta
color5  {s["base09"]}
color13 {s["base09"]}
#: cyan
color6  {s["base0c"]}
color14 {s["base0c"]}
#: white
color7  {s["base05"]}
color15 {s["base07"]}

mark1_foreground {s["base00"]}
mark1_background {s["base0d"]}
mark2_foreground {s["base00"]}
mark2_background {s["base0e"]}
mark3_foreground {s["base00"]}
mark3_background {s["base09"]}

active_tab_foreground {s["base00"]}
active_tab_background {s["base0d"]}
inactive_tab_foreground {s["base04"]}
inactive_tab_background {s["base01"]}

active_border_color {s["base0d"]}
inactive_border_color {s["base02"]}
"""
    out = HOME / ".config/kitty/colors/custom/matugen.conf"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def write_kitty_tailored(theme: str) -> bool:
    """Replace live kitty include with the official theme file when the slot has one.

    Personal themes without colorschemes/<theme>/kitty/ keep the matugen template.
    """
    slot = COLORSCHEMES / theme / "kitty" / "colors.conf"
    if not slot.is_file():
        return False
    text = slot.read_text(encoding="utf-8")
    match = re.search(r"include\s+custom/(\S+\.conf)", text)
    if match:
        src = HOME / ".config/kitty/colors/custom" / match.group(1)
    else:
        src = slot
    dest = HOME / ".config/kitty/colors/custom/matugen.conf"
    if not src.is_file():
        return False
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    return True


def overlay_user_accent(theme: str, slots: dict[str, str]) -> dict[str, str]:
    """Keep theme surfaces; set primary + source (base0D/base0F) from user-accent."""
    slots = normalize_slot_keys(slots)
    accent_path = COLORSCHEMES / theme / "user-accent"
    if not accent_path.is_file():
        return slots
    saved = accent_path.read_text(encoding="utf-8").strip().lower()
    if not saved.startswith("#"):
        saved = f"#{saved}"
    if len(saved) != 7:
        return slots
    slots["base0D"] = saved
    slots["base0F"] = saved
    return slots


def prepare_theme_palette(theme: str) -> dict[str, str]:
    """Resolve the slot palette, overlay Super+W source, persist palette.json."""
    slots = overlay_user_accent(theme, resolve_theme_slots(theme))
    export_palette_json(theme, slots, force=True)
    return slots


# Official Neovim colorschemes already on this install (lazy/).
# Other Super+W themes fall back to mini.base16 from the slot palette.
NVIM_COLORSCHEMES = {
    "catppuccin": "catppuccin-mocha",
    "gruvbox-dark": "gruvbox",
    "coast-gruv": "gruvbox",
    "warm-stone": "gruvbox",
    "everforest-dark": "everforest",
    "forest-night": "everforest",
    "nord-darker": "nord",
}

# lualine theme name for each :colorscheme (plugin-provided, not "auto").
NVIM_LUALINE_THEMES = {
    "catppuccin-mocha": "catppuccin",
    "gruvbox": "gruvbox",
    "everforest": "everforest",
    "nord": "nord",
}


def _lualine_lua(theme_name: str) -> str:
    return f"""pcall(function()
  local ll = require("lualine")
  local ok, cfg = pcall(ll.get_config)
  if not ok or not cfg then
    ll.setup({{ options = {{ theme = "{theme_name}" }} }})
    return
  end
  cfg.options = cfg.options or {{}}
  cfg.options.theme = "{theme_name}"
  ll.setup(cfg)
end)"""


def write_nvim_tailored(slots: dict[str, str], theme: str) -> None:
    """Prefer a real colorscheme plugin; otherwise paint mini.base16 from the slot."""
    colorscheme = NVIM_COLORSCHEMES.get(theme)
    if not colorscheme:
        write_nvim(slots, theme)
        return
    lualine = NVIM_LUALINE_THEMES.get(colorscheme, "auto")
    content = f"""-- Super+W official Neovim theme: {theme} → {colorscheme}
-- Do not replace with matugen mini.base16; that file is a Waypaper fallback.

vim.o.termguicolors = true
local ok = pcall(vim.cmd.colorscheme, "{colorscheme}")
if not ok then
  vim.notify("colorscheme {colorscheme} not found — install the plugin", vim.log.levels.WARN)
end
{_lualine_lua(lualine)}
"""
    out = HOME / ".config/nvim/lua/matugen-theme.lua"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def write_swaync_tailored(slots: dict[str, str], theme: str) -> None:
    """Copy official swaync custom CSS (bg0/fg/red). Fallback: map slot palette."""
    asset = resolve_asset(theme)
    dest = HOME / ".config/swaync/matugen/colors.css"
    dest.parent.mkdir(parents=True, exist_ok=True)
    src = HOME / ".config/swaync/colors/custom" / f"{asset}.css"
    if src.is_file():
        dest.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
        return
    s = {k.lower(): v for k, v in slots.items()}
    dest.write_text(
        f"""/* Super+W official SwayNC palette: {theme} (no leftover matugen roles) */
@define-color bg0 {s.get("base00", "#1d2021")};
@define-color bg1 {s.get("base01", "#282828")};
@define-color bg2 {s.get("base02", "#3c3836")};
@define-color bg3 {s.get("base01", "#282828")};
@define-color bg4 {s.get("base03", "#665c54")};

@define-color fg {s.get("base05", "#ebdbb2")};

@define-color red {s.get("base08", "#cc241d")};
@define-color orange {s.get("base0f", "#d65d0e")};
@define-color yellow {s.get("base0a", "#d79921")};
@define-color green {s.get("base0b", "#98971a")};
@define-color aqua {s.get("base0c", "#689d6a")};
@define-color blue {s.get("base0e", "#458588")};
@define-color purple {s.get("base09", "#b16286")};

@define-color grey0 {s.get("base04", "#928374")};
@define-color grey1 {s.get("base04", "#928374")};
@define-color grey2 {s.get("base03", "#665c54")};
""",
        encoding="utf-8",
    )


def write_tailored_overrides(slots: dict[str, str], theme: str) -> None:
    """Apps that ship official themes — write before leftover matugen."""
    write_starship(slots, theme)
    write_kitty_tailored(theme)
    write_nvim_tailored(slots, theme)
    # Hyprland template often skips on `matugen json` (hex_stripped); write slots directly.
    write_hypr(slots, theme)
    # Official palettes mapped to the rice CSS contract (not leftover Material You roles).
    write_waybar(slots, theme)
    write_rofi(slots, theme)
    write_swaync_tailored(slots, theme)


def write_all_outputs(slots: dict[str, str], theme: str) -> None:
    # Matugen --import-json is the distributor. This only restores tailored apps.
    write_tailored_overrides(slots, theme)


def seed_static_outputs(theme: str) -> dict[str, str]:
    """Write live files from the shipped palette — no matugen, no wallpaper extract."""
    slots = prepare_theme_palette(theme)
    write_waybar(slots, theme)
    write_hypr(slots, theme)
    write_rofi(slots, theme)
    write_mpv(slots, theme)
    write_tailored_overrides(slots, theme)
    return slots





# Super+W source-color splotches — hexes from colorschemes/<theme>/palette.json.
ACCENT_SLOT_ORDER = [
    "base08",
    "base09",
    "base0A",
    "base0B",
    "base0C",
    "base0D",
    "base0E",
    "base0F",
]

DEFAULT_ACCENT_LABELS = {
    "base08": "Red",
    "base09": "Purple",
    "base0A": "Yellow",
    "base0B": "Green",
    "base0C": "Aqua",
    "base0D": "Primary",
    "base0E": "Blue",
    "base0F": "Source",
}

THEME_ACCENT_LABELS: dict[str, dict[str, str]] = {
    "catppuccin": {
        "base08": "Red",
        "base09": "Mauve",
        "base0A": "Yellow",
        "base0B": "Green",
        "base0C": "Teal",
        "base0D": "Mauve",
        "base0E": "Blue",
        "base0F": "Peach",
    },
    "gruvbox-dark": {
        "base08": "Red",
        "base09": "Purple",
        "base0A": "Yellow",
        "base0B": "Green",
        "base0C": "Aqua",
        "base0D": "Orange",
        "base0E": "Blue",
        "base0F": "Orange",
    },
    "nord-darker": {
        "base08": "Red",
        "base09": "Purple",
        "base0A": "Yellow",
        "base0B": "Green",
        "base0C": "Frost",
        "base0D": "Blue",
        "base0E": "Blue",
        "base0F": "Orange",
    },
    "everforest-dark": {
        "base08": "Red",
        "base09": "Purple",
        "base0A": "Yellow",
        "base0B": "Green",
        "base0C": "Aqua",
        "base0D": "Green",
        "base0E": "Teal",
        "base0F": "Orange",
    },
    "noir": {
        "base08": "Rose",
        "base09": "Lilac",
        "base0A": "Sand",
        "base0B": "Sage",
        "base0C": "Teal",
        "base0D": "Grey",
        "base0E": "Steel",
        "base0F": "Stone",
    },
}

ACCENT_LABEL_ALIASES = {
    "coast-gruv": "gruvbox-dark",
    "warm-stone": "gruvbox-dark",
    "forest-night": "everforest-dark",
    "nord": "nord-darker",
}


def accent_labels_for(theme: str) -> dict[str, str]:
    key = ACCENT_LABEL_ALIASES.get(theme, theme)
    labels = dict(DEFAULT_ACCENT_LABELS)
    labels.update(THEME_ACCENT_LABELS.get(key, {}))
    return labels


def _valid_hex(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    hx = value.strip().lower()
    if not hx.startswith("#"):
        hx = f"#{hx}"
    if len(hx) != 7 or any(ch not in "0123456789abcdef" for ch in hx[1:]):
        return None
    return hx


def load_accent_slots_from_palette(theme: str) -> dict[str, str]:
    """Read accent hexes from palette.json only (no CSS rebuild, no user-accent)."""
    slots = load_palette_json(theme) or {}
    out: dict[str, str] = {}
    for key in ACCENT_SLOT_ORDER:
        hx = _valid_hex(slots.get(key.lower()))
        if hx:
            out[key.lower()] = hx
    return out


def list_theme_accents(theme: str) -> list[dict[str, str]]:
    """Unique source-color splotches from ~/.config/colorschemes/<theme>/palette.json."""
    slots = load_accent_slots_from_palette(theme)
    if len(slots) < 3:
        # Personal / incomplete slots: fill missing keys from the resolver,
        # but do not export or overwrite palette.json.
        try:
            fallback = resolve_theme_slots(theme)
        except FileNotFoundError:
            fallback = {}
        for key in ACCENT_SLOT_ORDER:
            lk = key.lower()
            if lk in slots:
                continue
            hx = _valid_hex(fallback.get(lk) or fallback.get(key))
            if hx:
                slots[lk] = hx

    labels = accent_labels_for(theme)
    default_hex = slots.get("base0d")
    seen: set[str] = set()
    out: list[dict[str, str]] = []
    for key in ACCENT_SLOT_ORDER:
        hx = slots.get(key.lower())
        if not hx or hx in seen:
            continue
        seen.add(hx)
        out.append(
            {
                "slot": key.lower(),
                "label": labels.get(key, DEFAULT_ACCENT_LABELS.get(key, key)),
                "hex": hx,
                "default": bool(default_hex and hx == default_hex),
            }
        )
    return out


def apply_source_accent(theme: str, hex_color: str) -> dict[str, str]:
    """Keep theme surfaces; set primary + source (base0D/base0F) to the chosen accent.

    Always starts from the theme's fixed palette, then overlays the accent — never
    leaves a half-applied state. Caller should run colors-config apply-static after
    for a full matugen-import rebuild of templates.
    """
    hex_color = hex_color.strip().lower()
    if not hex_color.startswith("#"):
        hex_color = f"#{hex_color}"
    if len(hex_color) != 7:
        raise ValueError(f"invalid hex color: {hex_color}")

    # Ignore THEME_SWITCHER_APPLY here — we need the theme base, then our accent.
    # (Caller unsets it; belt-and-suspenders if env leaked.)
    saved_tsa = os.environ.pop("THEME_SWITCHER_APPLY", None)
    try:
        slots = resolve_theme_slots(theme)
    finally:
        if saved_tsa is not None:
            os.environ["THEME_SWITCHER_APPLY"] = saved_tsa

    slots = normalize_slot_keys(slots)
    slots["base0D"] = hex_color
    slots["base0F"] = hex_color

    # Persist BEFORE write so any nested generator main() re-reads the accent
    accent_file = COLORSCHEMES / theme / "user-accent"
    accent_file.parent.mkdir(parents=True, exist_ok=True)
    accent_file.write_text(hex_color + "\n", encoding="utf-8")
    source_file = COLORSCHEMES / theme / "source-color"
    source_file.write_text(hex_color + "\n", encoding="utf-8")
    export_palette_json(theme, slots, force=True)

    write_tailored_overrides(slots, theme)
    return slots


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage:\n"
            "  generate-preset-colors.py <theme-name>\n"
            "  generate-preset-colors.py --prepare <theme-name>\n"
            "  generate-preset-colors.py --tailored <theme-name>\n"
            "  generate-preset-colors.py --seed <theme-name>\n"
            "  generate-preset-colors.py --list-accents <theme-name>\n"
            "  generate-preset-colors.py --apply-accent <theme-name> <#hex>",
            file=sys.stderr,
        )
        return 1

    if sys.argv[1] == "--list-accents":
        if len(sys.argv) < 3:
            print("Usage: generate-preset-colors.py --list-accents <theme>", file=sys.stderr)
            return 1
        accents = list_theme_accents(sys.argv[2].strip())
        print(json.dumps(accents, indent=2))
        return 0

    if sys.argv[1] == "--apply-accent":
        if len(sys.argv) < 4:
            print(
                "Usage: generate-preset-colors.py --apply-accent <theme> <#hex>",
                file=sys.stderr,
            )
            return 1
        theme = sys.argv[2].strip()
        hex_color = sys.argv[3].strip()
        slots = apply_source_accent(theme, hex_color)
        print(f"Accent applied for {theme}: primary/source = {slots['base0D']}")
        return 0

    if sys.argv[1] == "--prepare":
        if len(sys.argv) < 3:
            print("Usage: generate-preset-colors.py --prepare <theme>", file=sys.stderr)
            return 1
        theme = sys.argv[2].strip()
        slots = prepare_theme_palette(theme)
        print(f"Palette prepared for {theme}")
        print(f"  accent (primary): {slots['base0D']}")
        return 0

    if sys.argv[1] == "--tailored":
        if len(sys.argv) < 3:
            print("Usage: generate-preset-colors.py --tailored <theme>", file=sys.stderr)
            return 1
        theme = sys.argv[2].strip()
        slots = prepare_theme_palette(theme)
        write_tailored_overrides(slots, theme)
        print(f"Tailored overrides applied for {theme}")
        return 0

    if sys.argv[1] == "--seed":
        if len(sys.argv) < 3:
            print("Usage: generate-preset-colors.py --seed <theme>", file=sys.stderr)
            return 1
        theme = sys.argv[2].strip()
        slots = seed_static_outputs(theme)
        print(f"Static seed written for {theme}")
        print(f"  accent (primary): {slots['base0D']}")
        return 0

    theme = sys.argv[1].strip()
    slots = prepare_theme_palette(theme)
    write_tailored_overrides(slots, theme)
    print(f"Preset colors applied for {theme}")
    print(f"  accent (primary): {slots['base0D']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())