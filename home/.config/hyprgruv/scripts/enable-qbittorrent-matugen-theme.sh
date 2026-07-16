#!/usr/bin/env bash
# Point qBittorrent at the matugen-generated folder theme.
# Theme files are written by matugen templates; this only ensures preferences.
set -euo pipefail

CONF="${HOME}/.config/qBittorrent/qBittorrent.conf"
THEME_CONFIG="${HOME}/.config/qBittorrent/themes/matugen/config.json"
THEME_DIR="${HOME}/.config/qBittorrent/themes/matugen"

mkdir -p "$THEME_DIR"

if [[ ! -f "$THEME_CONFIG" ]]; then
    echo "[qbittorrent] Theme not generated yet: $THEME_CONFIG"
    exit 0
fi

if [[ ! -f "$CONF" ]]; then
    cat >"$CONF" <<EOF
[Preferences]
General\UseCustomUITheme=true
General\CustomUIThemePath=${THEME_CONFIG}
EOF
    echo "[qbittorrent] Created conf with matugen UI theme enabled"
    exit 0
fi

python3 - "$CONF" "$THEME_CONFIG" <<'PY'
import sys
from pathlib import Path

conf_path = Path(sys.argv[1])
theme_path = sys.argv[2]
text = conf_path.read_text(encoding="utf-8")
lines = text.splitlines()

# Parse into sections preserving order/unknown content
sections: dict[str, list[str]] = {}
order: list[str] = []
current = None
for line in lines:
    if line.startswith("[") and line.endswith("]"):
        current = line[1:-1]
        if current not in sections:
            sections[current] = []
            order.append(current)
        continue
    if current is None:
        # preamble
        if "__preamble__" not in sections:
            sections["__preamble__"] = []
            order.insert(0, "__preamble__")
        sections["__preamble__"].append(line)
        continue
    sections[current].append(line)

prefs = "Preferences"
if prefs not in sections:
    sections[prefs] = []
    order.append(prefs)

def set_key(section_lines: list[str], key: str, value: str) -> list[str]:
    prefix = key + "="
    out = []
    found = False
    for line in section_lines:
        if line.startswith(prefix) or line.startswith(key.replace("\\", "\\\\") + "="):
            if not found:
                out.append(f"{key}={value}")
                found = True
            # drop duplicates
            continue
        out.append(line)
    if not found:
        out.append(f"{key}={value}")
    return out

sections[prefs] = set_key(sections[prefs], r"General\UseCustomUITheme", "true")
sections[prefs] = set_key(sections[prefs], r"General\CustomUIThemePath", theme_path)

# Fusion + custom QSS is more reliable than Kvantum fighting the stylesheet.
appearance = "Appearance"
if appearance not in sections:
    sections[appearance] = []
    order.append(appearance)
sections[appearance] = set_key(sections[appearance], "Style", "Fusion")

parts = []
for name in order:
    if name == "__preamble__":
        parts.extend(sections[name])
        continue
    parts.append(f"[{name}]")
    parts.extend(sections[name])
    if parts and parts[-1] != "":
        parts.append("")

conf_path.write_text("\n".join(parts).rstrip() + "\n", encoding="utf-8")
print(f"[qbittorrent] Custom UI theme -> {theme_path}")
print("[qbittorrent] Restart qBittorrent to apply palette changes")
PY
