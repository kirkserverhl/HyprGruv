#!/usr/bin/env python3
"""Build matugen --import-json from pywal, matugen base16, and optional user overrides."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

HOME = Path.home()
ROLES_PATH = HOME / ".config/matugen/roles.json"
USER_PALETTE_PATH = HOME / ".config/matugen/user-palette.json"
SPECTRUM_SCALE = HOME / ".config/hyprgruv/scripts/spectrum-scale.py"
SEMANTIC_MAP = {
    "surface_container_lowest": "base00",
    "surface_container_low": "base01",
    "surface_container": "base02",
    "outline_variant": "base03",
    "on_surface_variant": "base04",
    "on_surface": "base05",
    "inverse_on_surface": "base06",
    "surface_bright": "base07",
    "error": "base08",
    "tertiary": "base09",
    "secondary": "base0a",
    "primary": "base0b",
    "tertiary_container": "base0c",
    "secondary_container": "base0e",
    "source_color": "base0f",
    "surface": "base00",
    "on_primary": "base00",
    "on_secondary": "base00",
    "on_tertiary": "base00",
    "on_error": "base00",
}

BASE16_SLOTS = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
    "base08", "base09", "base0a", "base0b", "base0c", "base0d", "base0e", "base0f",
]


def mode_node(hexv: str) -> dict[str, Any]:
    hexv = hexv if hexv.startswith("#") else f"#{hexv}"
    stripped = hexv.lstrip("#")
    return {
        "dark": {"hex": hexv, "color": hexv, "hex_stripped": stripped},
        "default": {"hex": hexv, "color": hexv, "hex_stripped": stripped},
        "light": {"hex": hexv, "color": hexv, "hex_stripped": stripped},
    }


def pick_wal(colors: dict[str, str], key: str, fallback: str = "#888888") -> str:
    val = colors.get(key)
    return val if isinstance(val, str) and val.startswith("#") else fallback


def base16_from_wal(wal_colors: dict[str, str]) -> dict[str, str]:
    return {
        "base00": pick_wal(wal_colors, "color0"),
        "base08": pick_wal(wal_colors, "color1"),
        "base0b": pick_wal(wal_colors, "color2"),
        "base0a": pick_wal(wal_colors, "color3"),
        "base0f": pick_wal(wal_colors, "color4"),
        "base0e": pick_wal(wal_colors, "color5"),
        "base0c": pick_wal(wal_colors, "color6"),
        "base05": pick_wal(wal_colors, "color7"),
        "base03": pick_wal(wal_colors, "color8"),
        "base09": pick_wal(wal_colors, "color9"),
        "base07": pick_wal(wal_colors, "color15"),
        "base01": pick_wal(wal_colors, "color8", pick_wal(wal_colors, "color0")),
        "base02": pick_wal(wal_colors, "color8", pick_wal(wal_colors, "color0")),
        "base04": pick_wal(wal_colors, "color3", pick_wal(wal_colors, "color7")),
        "base06": pick_wal(wal_colors, "color15", pick_wal(wal_colors, "color7")),
        "base0d": pick_wal(wal_colors, "color4", pick_wal(wal_colors, "color2")),
    }


def hex_from_matugen_node(node: Any) -> str | None:
    if isinstance(node, str) and node.startswith("#"):
        return node
    if isinstance(node, dict):
        for key in ("dark", "default", "light"):
            sub = node.get(key)
            if isinstance(sub, dict):
                for field in ("hex", "color"):
                    val = sub.get(field)
                    if isinstance(val, str) and val.startswith("#"):
                        return val
            elif isinstance(sub, str) and sub.startswith("#"):
                return sub
    return None


def base16_from_matugen_json(data: dict[str, Any]) -> dict[str, str]:
    raw = data.get("base16") or {}
    out: dict[str, str] = {}
    for slot in BASE16_SLOTS:
        hexv = hex_from_matugen_node(raw.get(slot))
        if hexv:
            out[slot] = hexv
    return out


def run_wal(wallpaper: Path) -> dict[str, str]:
    subprocess.run(
        ["wal", "-i", str(wallpaper), "-n", "-q"],
        stdin=subprocess.DEVNULL,
        check=False,
        capture_output=True,
    )
    wal_json = HOME / ".cache/wal/colors.json"
    if not wal_json.is_file():
        raise RuntimeError(f"pywal did not produce {wal_json}")
    payload = json.loads(wal_json.read_text(encoding="utf-8"))
    cached = payload.get("wallpaper")
    if cached and cached != str(wallpaper):
        raise RuntimeError(f"wal cache mismatch: {cached} != {wallpaper}")
    colors = payload.get("colors") or {}
    if not isinstance(colors, dict):
        raise RuntimeError("invalid wal colors.json")
    return colors


def run_matugen_base16(wallpaper: Path) -> dict[str, str]:
    proc = subprocess.run(
        [
            "matugen", "image", str(wallpaper),
            "--mode", "dark", "--type", "scheme-tonal-spot",
            "--source-color-index", "0",
            "--dry-run", "--json", "hex",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "matugen dry-run failed")
    data = json.loads(proc.stdout)
    slots = base16_from_matugen_json(data)
    if len(slots) < 8:
        raise RuntimeError("matugen returned incomplete base16")
    return slots


def normalize_base16_keys(raw: dict[str, Any]) -> dict[str, Any]:
    """palette.json uses mixed-case slot names (base0A); normalize to lowercase."""
    return {k.lower(): v for k, v in raw.items() if isinstance(k, str)}


def base16_hex_from_json(data: dict[str, Any]) -> dict[str, str]:
    raw = data.get("base16") or {}
    if not isinstance(raw, dict):
        return {}
    raw = normalize_base16_keys(raw)
    out: dict[str, str] = {}
    for slot in BASE16_SLOTS:
        val = raw.get(slot)
        if isinstance(val, str) and val.startswith("#"):
            out[slot] = val
        elif isinstance(val, dict):
            hexv = hex_from_matugen_node(val)
            if hexv:
                out[slot] = hexv
    return out


def load_user_palette(wallpaper: Path) -> dict[str, str] | None:
    if not USER_PALETTE_PATH.is_file():
        return None
    payload = json.loads(USER_PALETTE_PATH.read_text(encoding="utf-8"))
    saved_wp = payload.get("wallpaper")
    if saved_wp and saved_wp != str(wallpaper):
        return None
    base16 = payload.get("base16")
    if not isinstance(base16, dict):
        return None
    base16 = normalize_base16_keys(base16)
    out: dict[str, str] = {}
    for slot in BASE16_SLOTS:
        val = base16.get(slot)
        if isinstance(val, str) and val.startswith("#"):
            out[slot] = val
    return out or None


def build_import_payload(
    wallpaper: Path,
    *,
    source: str = "wal",
    base16_hex: dict[str, str] | None = None,
    wal_colors: dict[str, str] | None = None,
) -> dict[str, Any]:
    if base16_hex is None:
        if source == "matugen":
            base16_hex = run_matugen_base16(wallpaper)
        else:
            wal_colors = wal_colors or run_wal(wallpaper)
            base16_hex = base16_from_wal(wal_colors)

    base16 = {slot: mode_node(hexv) for slot, hexv in base16_hex.items()}
    matugen_colors = {name: base16[slot] for name, slot in SEMANTIC_MAP.items() if slot in base16}

    payload: dict[str, Any] = {
        "image": str(wallpaper),
        "mode": "dark",
        "colors": matugen_colors,
        "base16": base16,
        "palette_source": source,
    }
    if wal_colors:
        payload["wal"] = {"wallpaper": str(wallpaper), "colors": wal_colors}
    return payload


def run_spectrum_scale(wallpaper: Path) -> dict[str, Any]:
    if not SPECTRUM_SCALE.is_file():
        raise RuntimeError(f"spectrum-scale helper missing: {SPECTRUM_SCALE}")
    import importlib.util

    spec = importlib.util.spec_from_file_location("spectrum_scale", SPECTRUM_SCALE)
    if spec is None or spec.loader is None:
        raise RuntimeError("failed to load spectrum-scale.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.build_base16_from_wallpaper(wallpaper)


def export_theme_palette(wallpaper: Path, theme: str, out_path: Path) -> dict[str, str]:
    """Write theme palette.json from wallpaper hues (spectrum-scale, not pywal averages)."""
    from datetime import datetime, timezone

    scaled = run_spectrum_scale(wallpaper)
    base16_hex = scaled["base16"]
    payload = {
        "version": 2,
        "theme": theme,
        "source": "spectrum-scale",
        "wallpaper": str(wallpaper),
        "saved_at": datetime.now(timezone.utc).isoformat(),
        "base16": base16_hex,
        "spectrum": scaled.get("spectrum"),
        "bands": scaled.get("bands"),
        "assigned": scaled.get("assigned"),
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return base16_hex


def preview_both(wallpaper: Path) -> dict[str, Any]:
    wal_colors = run_wal(wallpaper)
    wal_base16 = base16_from_wal(wal_colors)
    try:
        spectrum = run_spectrum_scale(wallpaper)
    except Exception as exc:  # noqa: BLE001
        spectrum = {"_error": str(exc)}
    try:
        matugen_base16 = run_matugen_base16(wallpaper)
    except Exception as exc:  # noqa: BLE001
        matugen_base16 = {"_error": str(exc)}
    return {
        "wallpaper": str(wallpaper),
        "wal": {"colors": wal_colors, "base16": wal_base16},
        "spectrum_scale": spectrum,
        "matugen": {"base16": matugen_base16},
    }


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: palette-build-import.py <command> ...", file=sys.stderr)
        return 2

    cmd = sys.argv[1]
    if cmd == "preview" and len(sys.argv) >= 3:
        print(json.dumps(preview_both(Path(sys.argv[2])), indent=2))
        return 0

    if cmd == "export-theme" and len(sys.argv) >= 5:
        wallpaper = Path(sys.argv[2])
        theme = sys.argv[3]
        out_path = Path(sys.argv[4])
        export_theme_palette(wallpaper, theme, out_path)
        print(out_path)
        return 0

    if cmd == "build" and len(sys.argv) >= 4:
        wallpaper = Path(sys.argv[2])
        out_path = Path(sys.argv[3])
        source = sys.argv[4] if len(sys.argv) > 4 else "wal"
        custom = load_user_palette(wallpaper)
        if custom:
            payload = build_import_payload(wallpaper, source="custom", base16_hex=custom)
        elif source in ("custom", "wal", "spectrum", "spectrum-scale"):
            scaled = run_spectrum_scale(wallpaper)
            payload = build_import_payload(
                wallpaper,
                source="spectrum-scale",
                base16_hex=scaled["base16"],
            )
            payload["spectrum"] = scaled.get("spectrum")
            payload["bands"] = scaled.get("bands")
        else:
            payload = build_import_payload(wallpaper, source=source)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(out_path)
        return 0

    if cmd == "build-base16" and len(sys.argv) >= 5:
        palette_path = Path(sys.argv[2])
        wallpaper = Path(sys.argv[3])
        out_path = Path(sys.argv[4])
        data = json.loads(palette_path.read_text(encoding="utf-8"))
        base16_hex = base16_hex_from_json(data)
        if len(base16_hex) < 8:
            print("build-base16: need at least 8 base16 slots", file=sys.stderr)
            return 2
        payload = build_import_payload(wallpaper, source="saved", base16_hex=base16_hex)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(out_path)
        return 0

    print("unknown command", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())