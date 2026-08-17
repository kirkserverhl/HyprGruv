#!/usr/bin/env python3
"""Drop named [templates.<id>] sections from a matugen config.toml.

Used by Super+W so matugen never writes apps that already have an official
preset (starship, kitty, neovim, hyprland, obsidian, waybar, swaync, rofi,
wlogout). Waypaper / free wallpaper still uses the full config.
"""

from __future__ import annotations

import sys
from pathlib import Path


def strip_templates(text: str, skip: set[str]) -> str:
    out: list[str] = []
    dropping = False
    for line in text.splitlines(keepends=True):
        stripped = line.lstrip()
        if stripped.startswith("[") and "]" in stripped:
            header = stripped[1 : stripped.index("]")].strip()
            if header.startswith("templates."):
                name = header.split(".", 1)[1]
                dropping = name in skip
            else:
                dropping = False
            if dropping:
                continue
        if dropping:
            continue
        out.append(line)
    return "".join(out)


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: matugen-strip-templates.py <src.toml> <dst.toml> [template-id ...]",
            file=sys.stderr,
        )
        return 1
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])
    skip = {name.strip() for name in sys.argv[3:] if name.strip()}
    if not src.is_file():
        print(f"missing {src}", file=sys.stderr)
        return 1
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(strip_templates(src.read_text(encoding="utf-8"), skip), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
