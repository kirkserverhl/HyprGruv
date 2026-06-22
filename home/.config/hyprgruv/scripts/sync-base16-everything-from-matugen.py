#!/usr/bin/env python3
"""Write ~/.config/base16-everything/config.yaml from the active matugen palette."""

from __future__ import annotations

import json
import sys
from pathlib import Path

HOME = Path.home()
OUT = HOME / ".config" / "base16-everything" / "config.yaml"
PENDING = HOME / ".cache/matugen/pending-run.json"
CURRENT_THEME = HOME / ".config/colorschemes/.current-theme"

SLOTS_16 = [
    "base00",
    "base01",
    "base02",
    "base03",
    "base04",
    "base05",
    "base06",
    "base07",
    "base08",
    "base09",
    "base0a",
    "base0b",
    "base0c",
    "base0d",
    "base0e",
    "base0f",
]

YAML_SLOTS = [
    "base00",
    "base01",
    "base02",
    "base03",
    "base04",
    "base05",
    "base06",
    "base07",
    "base08",
    "base09",
    "base0A",
    "base0B",
    "base0C",
    "base0D",
    "base0E",
    "base0F",
    "base10",
    "base11",
    "base12",
    "base13",
    "base14",
    "base15",
    "base16",
    "base17",
]


def read_json(path: Path) -> dict | None:
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def normalize_base16(raw: dict) -> dict[str, str]:
    out: dict[str, str] = {}
    if not isinstance(raw, dict):
        return out
    for key, val in raw.items():
        slot = str(key).lower()
        if not slot.startswith("base"):
            continue
        if isinstance(val, str) and val.startswith("#"):
            out[slot] = val.lower()
        elif isinstance(val, dict):
            for mode in ("dark", "default"):
                node = val.get(mode)
                if isinstance(node, dict):
                    color = node.get("color") or node.get("hex")
                    if isinstance(color, str) and color.startswith("#"):
                        out[slot] = color.lower()
                        break
                elif isinstance(node, str) and node.startswith("#"):
                    out[slot] = node.lower()
                    break
    return out


def color_hex(obj: dict, key: str, fallback: str = "#888888") -> str:
    node: object = obj
    for part in key.split("."):
        if not isinstance(node, dict):
            return fallback
        node = node.get(part, {})
    if isinstance(node, str) and node.startswith("#"):
        return node.lower()
    if isinstance(node, dict):
        for mode in ("default", "dark"):
            val = node.get(mode)
            if isinstance(val, dict):
                color = val.get("color") or val.get("hex")
                if isinstance(color, str) and color.startswith("#"):
                    return color.lower()
            elif isinstance(val, str) and val.startswith("#"):
                return val.lower()
    return fallback


def base16_from_matugen(data: dict) -> dict[str, str]:
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
    out: dict[str, str] = {}
    for slot, material in material_map.items():
        hexval = color_hex({"v": colors.get(material, {})}, "v", "")
        if hexval.startswith("#"):
            out[slot] = hexval
    return out


def score_source(path: Path, data: dict, pending: dict, theme_hint: str) -> int:
    if not data:
        return -1
    base16 = data.get("base16") if "base16" in data else base16_from_matugen(data)
    if len(normalize_base16(base16 if isinstance(base16, dict) else {})) < 8:
        if len(base16_from_matugen(data)) < 8:
            return -1

    score = 16
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
        "user-palette.json",
        "current-palette.json",
    }:
        score += 500_000
    if path.name == "current.json" and method in {"saved-config", "preset-static"}:
        score -= 500_000
    return score


def pick_palette() -> tuple[dict[str, str], str, str]:
    pending = read_json(PENDING) or {}
    theme_hint = ""
    if CURRENT_THEME.is_file():
        theme_hint = CURRENT_THEME.read_text(encoding="utf-8").strip()

    candidates: list[tuple[Path, dict]] = []
    cache = HOME / ".cache/matugen"
    colorschemes = HOME / ".config/colorschemes"

    for rel in (
        cache / "current.json",
        HOME / ".config/matugen/user-palette.json",
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
        raise SystemExit(0)

    best_path, best_data = max(
        candidates, key=lambda item: score_source(item[0], item[1], pending, theme_hint)
    )

    base16 = best_data.get("base16") if "base16" in best_data else {}
    base16 = normalize_base16(base16) or base16_from_matugen(best_data)
    if len(base16) < 8:
        raise SystemExit(0)

    theme_name = (
        (best_data.get("theme") or "").strip()
        or theme_hint
        or (pending.get("theme") or "").strip()
        or "matugen"
    )
    variant = "dark"
    if isinstance(best_data.get("is_dark_mode"), bool):
        variant = "dark" if best_data["is_dark_mode"] else "light"
    elif (pending.get("mode") or "").strip().lower() == "light":
        variant = "light"
    elif (best_data.get("mode") or "").strip().lower() == "light":
        variant = "light"

    return base16, theme_name, variant


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"


def lerp(a: int, b: int, t: float) -> int:
    return max(0, min(255, round(a + (b - a) * t)))


def lerp_hex(c1: str, c2: str, t: float) -> str:
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex(lerp(r1, r2, t), lerp(g1, g2, t), lerp(b1, b2, t))


def lighten(hex_color: str, amount: float = 0.28) -> str:
    return lerp_hex(hex_color, "#ffffff", amount)


def darken(hex_color: str, amount: float = 0.18) -> str:
    return lerp_hex(hex_color, "#000000", amount)


def slot(base16: dict[str, str], name: str) -> str:
    return base16.get(name.lower()) or base16.get(name) or "#888888"


def extend_base24(base16: dict[str, str]) -> dict[str, str]:
    core = {s: slot(base16, s) for s in SLOTS_16}
    return {
        **core,
        "base10": lerp_hex(core["base00"], core["base01"], 0.42),
        "base11": darken(core["base00"], 0.14),
        "base12": lighten(core["base08"], 0.30),
        "base13": lighten(core["base09"], 0.30),
        "base14": lighten(core["base0a"], 0.30),
        "base15": lighten(core["base0b"], 0.30),
        "base16": lighten(core["base0c"], 0.30),
        "base17": lighten(core["base0d"], 0.30),
    }


def yaml_key(slot_name: str) -> str:
    if len(slot_name) == 5 and slot_name.startswith("base0") and slot_name[-1].isalpha():
        return "base0" + slot_name[-1].upper()
    return slot_name


def write_config(base16: dict[str, str], theme_name: str, variant: str) -> None:
    palette = extend_base24(base16)
    lines = [
        "# Generated by hyprgruv sync-base16-everything-from-matugen.py",
        "# Base16 Everything reads this via native messaging (premium).",
        "",
        'system: "base24"',
        f'name: "Matugen — {theme_name}"',
        'author: "matugen / hyprgruv"',
        f'variant: "{variant}"',
        "",
        "palette:",
    ]

    for yaml_slot in YAML_SLOTS:
        key = yaml_slot.lower()
        lines.append(f'  {yaml_slot}: "{palette[key]}"')

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    base16, theme_name, variant = pick_palette()
    write_config(base16, theme_name, variant)


if __name__ == "__main__":
    main()