#!/usr/bin/env python3
"""Build a wallpaper spectrum scale backwards from UI layout (Starship → Waybar → Hyprbars).

Matugen goes image → semantic roles → templates. This goes the other way:
  UI column order (purple → blue → green → yellow → orange → red)
  ← literal saturated hues extracted from the wallpaper.

Most images only yield ~4 distinct accents (through yellow); orange/red slots are
skipped when those hues are not present in the image.
"""

from __future__ import annotations

import colorsys
import json
from pathlib import Path
from typing import Any

HOME = Path.home()
SCALE_PATH = HOME / ".config/matugen/spectrum-scale.json"

# Reversed rainbow — far-left Starship source first, neutral tail last.
HUE_COLUMNS: list[tuple[str, str, str]] = [
    ("purple", "base0f", "color_orange"),
    ("blue", "base08", "color_yellow"),
    ("green", "base0b", "color_aqua"),
    ("yellow", "base0a", "color_blue"),
    ("orange", "base0e", "color_bg3"),
    ("red", "base09", "color_red"),
]

# Target hues (HLS 0–1) for matching literal wallpaper accents to UI columns.
HUE_TARGETS: dict[str, float] = {
    "purple": 0.86,
    "blue": 0.53,
    "green": 0.33,
    "yellow": 0.12,
    "orange": 0.07,
    "red": 0.02,
}

SPECTRUM_KEYS = [
    "color_orange",
    "color_yellow",
    "color_aqua",
    "color_blue",
    "color_bg3",
    "color_bg1",
]


def load_scale_template() -> dict[str, Any]:
    if not SCALE_PATH.is_file():
        return {
            "version": 1,
            "description": "UI spectrum columns filled from wallpaper hues (high hue → low)",
            "ui_order": [label for label, _, _ in HUE_COLUMNS],
            "max_columns": len(HUE_COLUMNS),
        }
    return json.loads(SCALE_PATH.read_text(encoding="utf-8"))


def _hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02x}{:02x}{:02x}".format(*rgb)


def _saturation(rgb: tuple[int, int, int]) -> float:
    r, g, b = (c / 255 for c in rgb)
    return colorsys.rgb_to_hls(r, g, b)[2]


def _hue(rgb: tuple[int, int, int]) -> float:
    r, g, b = (c / 255 for c in rgb)
    return colorsys.rgb_to_hls(r, g, b)[0]


def _luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = (c / 255 for c in rgb)
    return colorsys.rgb_to_hls(r, g, b)[1]


def _dist(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return sum(abs(x - y) for x, y in zip(a, b))


def _avg(colors: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    n = len(colors)
    return tuple(sum(c[i] for c in colors) // n for i in range(3))  # type: ignore[return-value]


def _hue_distance(a: float, b: float) -> float:
    d = abs(a - b)
    return min(d, 1.0 - d)


def _match_hue_targets(samples: list[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    """Pick the best saturated pixel per reversed-rainbow column."""
    bands: list[tuple[int, int, int]] = []
    used: list[tuple[int, int, int]] = []

    for label, _, _ in HUE_COLUMNS:
        target = HUE_TARGETS[label]
        best: tuple[int, int, int] | None = None
        best_score = 0.0
        for rgb in samples:
            if any(_dist(rgb, u) < 30 for u in used):
                continue
            sat = _saturation(rgb)
            if sat < 0.20:
                continue
            dh = _hue_distance(_hue(rgb), target)
            if dh > 0.14:
                continue
            score = sat * (1.0 - dh * 3.0)
            if score > best_score:
                best_score = score
                best = rgb
        if best is not None and best_score > 0.20:
            bands.append(best)
            used.append(best)

    return bands


def extract_saturated_bands(wallpaper: Path, *, max_bands: int = 8) -> list[tuple[int, int, int]]:
    """Return distinct saturated RGB bands sorted purple → red (hue descending)."""
    try:
        from PIL import Image
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError("Pillow required for spectrum-scale extraction") from exc

    img = Image.open(wallpaper).convert("RGB")
    w, h = img.size

    # Prefer the right half (rainbow wallpapers) but fall back to full frame.
    x_start, x_end = int(w * 0.42), int(w * 0.96)
    y_start, y_end = int(h * 0.30), int(h * 0.70)

    samples: list[tuple[int, int, int]] = []
    for y in range(y_start, y_end):
        for x in range(x_start, x_end):
            rgb = img.getpixel((x, y))
            if max(rgb) < 45:
                continue
            if min(rgb) > 210 and _saturation(rgb) < 0.12:
                continue
            if _saturation(rgb) < 0.20 and _luminance(rgb) < 0.55:
                continue
            samples.append(rgb)

    if len(samples) < 64:
        samples = []
        for y in range(0, h, max(1, h // 200)):
            for x in range(0, w, max(1, w // 200)):
                rgb = img.getpixel((x, y))
                if _saturation(rgb) < 0.22:
                    continue
                if max(rgb) < 40:
                    continue
                samples.append(rgb)

    if not samples:
        raise RuntimeError(f"no saturated colors found in {wallpaper}")

    # Stripe-first: single vertical slice through angled rainbow bands (Dark Side–style).
    slice_x = int(w * 0.72)
    vertical: list[tuple[int, int, int]] = []
    for y in range(y_start, y_end):
        rgb = img.getpixel((slice_x, y))
        if max(rgb) < 40 or _saturation(rgb) < 0.20:
            continue
        vertical.append(rgb)

    bands: list[tuple[int, int, int]] = []
    if vertical:
        prev = vertical[0]
        bucket = [prev]
        for rgb in vertical[1:]:
            dh = abs(_hue(rgb) - _hue(prev))
            dh = min(dh, 1.0 - dh)
            if dh > 0.040 or _dist(rgb, prev) > 55:
                bands.append(_avg(bucket))
                bucket = [rgb]
                prev = rgb
            else:
                bucket.append(rgb)
        if bucket:
            bands.append(_avg(bucket))

    if len(bands) >= 4:
        # Physical stripe order is red→purple top→bottom; UI wants purple→red (reversed).
        ordered = list(reversed(bands))
        merged: list[tuple[int, int, int]] = []
        for rgb in ordered:
            if not merged:
                merged.append(rgb)
                continue
            dh = _hue_distance(_hue(rgb), _hue(merged[-1]))
            if dh < 0.030 and _dist(rgb, merged[-1]) < 40:
                merged[-1] = _avg([merged[-1], rgb])
            else:
                merged.append(rgb)
        while len(merged) > len(HUE_COLUMNS):
            best_i, best_d = 0, 2.0
            for i in range(len(merged) - 1):
                d = _hue_distance(_hue(merged[i]), _hue(merged[i + 1]))
                if d < best_d:
                    best_d, best_i = d, i
            merged[best_i] = _avg([merged[best_i], merged[best_i + 1]])
            del merged[best_i + 1]
        return merged[:max_bands]

    matched = _match_hue_targets(samples)
    if len(matched) >= 3:
        return matched[:max_bands]

    if len(bands) < 3:
        # Global hue buckets fallback.
        buckets: dict[int, list[tuple[int, int, int]]] = {}
        for rgb in samples:
            key = int(_hue(rgb) * 24) % 24
            buckets.setdefault(key, []).append(rgb)
        bands = [_avg(v) for v in buckets.values() if len(v) >= 12]
        if len(bands) < 3:
            bands = [_avg(v) for v in buckets.values()]

    bands.sort(key=lambda c: (_hue(c) < 0.06, -_hue(c)))
    return bands[:max_bands]


def extract_neutrals(wallpaper: Path) -> tuple[str, str, str]:
    """Return (background, muted, foreground) hex from low-saturation wallpaper pixels."""
    try:
        from PIL import Image
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError("Pillow required for spectrum-scale extraction") from exc

    img = Image.open(wallpaper).convert("RGB")
    w, h = img.size
    pixels: list[tuple[int, int, int]] = []
    for y in range(0, h, max(1, h // 120)):
        for x in range(0, w, max(1, w // 120)):
            pixels.append(img.getpixel((x, y)))

    neutral = [p for p in pixels if _saturation(p) < 0.18]
    dark = [p for p in neutral if _luminance(p) < 0.20]
    light = [p for p in neutral if _luminance(p) > 0.55]
    mid = [p for p in neutral if 0.20 <= _luminance(p) <= 0.55]

    bg = _hex(_avg(dark)) if dark else "#181818"
    fg = _hex(_avg(light)) if light else "#d4d4d4"
    muted = _hex(_avg(mid)) if mid else bg
    return bg, muted, fg


def build_base16_from_wallpaper(wallpaper: Path) -> dict[str, Any]:
    """Full base16 + spectrum metadata from image-only colors."""
    bands = extract_saturated_bands(wallpaper)
    bg, muted, fg = extract_neutrals(wallpaper)

    accent = _hex(bands[0]) if bands else fg
    base16: dict[str, str] = {
        "base00": bg,
        "base01": muted,
        "base02": muted,
        "base03": muted,
        "base04": _hex(bands[min(2, len(bands) - 1)]) if bands else fg,
        "base05": fg,
        "base06": fg,
        "base07": fg,
        "base0c": _hex(bands[min(1, len(bands) - 1)]) if bands else accent,
        "base0d": accent,
    }

    assigned: list[dict[str, str]] = []
    used: list[tuple[int, int, int]] = []
    for label, slot, spectrum_key in HUE_COLUMNS:
        target = HUE_TARGETS[label]
        best: tuple[int, int, int] | None = None
        best_d = 2.0
        for rgb in bands:
            if rgb in used:
                continue
            d = _hue_distance(_hue(rgb), target)
            if d < best_d:
                best_d, best = d, rgb
        if best is None or best_d > 0.18:
            break
        used.append(best)
        hx = _hex(best)
        base16[slot] = hx
        assigned.append({"hue": label, "slot": slot, "spectrum": spectrum_key, "hex": hx})

    # Tail neutral for Starship time / Waybar chrome — never invented, dimmer fg or muted.
    base16.setdefault("base02", muted)

    spectrum: dict[str, str] = {
        "color_fg0": base16["base05"],
        "color_bg1": base16["base02"],
        "color_on_orange": base16["base00"],
        "color_on_yellow": base16["base00"],
        "color_on_aqua": base16["base00"],
        "color_on_blue": base16["base05"],
        "color_green": base16.get("base0b", base16["base0d"]),
        "color_purple": base16.get("base0f", base16["base0d"]),
        "color_red": base16.get("base09", base16.get("base08", base16["base0d"])),
    }

    for label, slot, spectrum_key in HUE_COLUMNS:
        if slot in base16:
            spectrum[spectrum_key] = base16[slot]

    # Neutral tail only when we did not reach orange/red columns.
    if "base0e" in base16:
        spectrum["color_bg3"] = base16["base0e"]
    elif assigned:
        spectrum["color_bg3"] = assigned[-1]["hex"]

    return {
        "base16": base16,
        "spectrum": spectrum,
        "bands": [_hex(b) for b in bands],
        "assigned": assigned,
        "wallpaper": str(wallpaper),
        "template": load_scale_template(),
    }


def preview(wallpaper: Path) -> dict[str, Any]:
    data = build_base16_from_wallpaper(wallpaper)
    lines = []
    for item in data["assigned"]:
        lines.append(f"{item['spectrum']:14} ← {item['hue']:7} {item['hex']} ({item['slot']})")
    data["ui_map"] = lines
    return data


def main() -> int:
    import sys

    if len(sys.argv) < 3:
        print("usage: spectrum-scale.py preview <wallpaper>", file=sys.stderr)
        print("       spectrum-scale.py base16 <wallpaper>", file=sys.stderr)
        return 2

    cmd = sys.argv[1]
    wallpaper = Path(sys.argv[2])
    if not wallpaper.is_file():
        print(f"missing wallpaper: {wallpaper}", file=sys.stderr)
        return 1

    if cmd == "preview":
        print(json.dumps(preview(wallpaper), indent=2))
        return 0

    if cmd == "base16":
        data = build_base16_from_wallpaper(wallpaper)
        print(json.dumps(data["base16"], indent=2))
        return 0

    print("unknown command", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())