#!/usr/bin/env bash
# Copy the active starship rainbow palette into a Waybar CSS snippet
# so freshstart stays in lockstep with the prompt when themes change.
set -euo pipefail

starship_cfg="${HOME}/.config/starship.toml"
out="${HOME}/.config/waybar/colors/starship-rainbow.css"

[[ -f "$starship_cfg" || -L "$starship_cfg" ]] || exit 0

python3 - "$starship_cfg" "$out" <<'PY'
import re, sys
from pathlib import Path

src, dest = Path(sys.argv[1]), Path(sys.argv[2])
text = src.read_text(encoding="utf-8")
pairs = dict(re.findall(r'^(color_\w+)\s*=\s*"(#[0-9A-Fa-f]{6})"', text, re.M))
keys = [
    "color_fg0", "color_bg1", "color_bg3",
    "color_orange", "color_yellow", "color_aqua", "color_blue",
    "color_on_orange", "color_on_yellow", "color_on_aqua", "color_on_blue",
    "color_red", "color_green", "color_purple",
]
if not any(k in pairs for k in keys):
    sys.exit(0)
dest.parent.mkdir(parents=True, exist_ok=True)
lines = [
    "/* Generated from the active starship palette. */",
    "/* Rewritten by waybar/scripts/sync-starship-colors.sh */",
    "",
]
for k in keys:
    if k in pairs:
        lines.append(f"@define-color {k} {pairs[k]};")
dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
