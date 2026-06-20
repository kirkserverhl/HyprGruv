#!/usr/bin/env bash
# sync-kde-qt-theme.sh — align Qt/KDE settings with matugen + theme picker assets
#
# Usage:
#   sync-kde-qt-theme.sh [theme] [icon-theme] [look-and-feel]
#   sync-kde-qt-theme.sh              # reads .current-theme + theme-assets.sh

set -euo pipefail

THEME="${1:-}"
ICON_THEME="${2:-}"
KDE_LNF="${3:-}"

COLORSCHEMES_DIR="${HOME}/.config/colorschemes"
KDEGLOBALS="${HOME}/.config/kdeglobals"
SCHEME_FILE="${HOME}/.local/share/color-schemes/Matugen.colors"
KVANTUM_CONF="${HOME}/.config/Kvantum/kvantum.kvconfig"

# shellcheck source=/dev/null
source "$COLORSCHEMES_DIR/theme-assets.sh"

if [[ -z "$THEME" && -f "$COLORSCHEMES_DIR/.current-theme" ]]; then
    THEME=$(tr -d '[:space:]' <"$COLORSCHEMES_DIR/.current-theme")
fi
[[ -n "$THEME" ]] || THEME="gruvbox-dark"

[[ -n "$ICON_THEME" ]] || ICON_THEME=$(resolve_icon_theme "$THEME")
[[ -n "$KDE_LNF" ]] || KDE_LNF=$(resolve_kde_lookandfeel "$THEME")

ensure_kvantum_theme() {
    [[ -f "$KVANTUM_CONF" ]] || return 0
    if grep -q '^theme=' "$KVANTUM_CONF"; then
        sed -i 's|^theme=.*|theme=matugen|' "$KVANTUM_CONF"
    else
        printf '\n[General]\ntheme=matugen\n' >>"$KVANTUM_CONF"
    fi
}

sync_kdeglobals() {
    [[ -f "$SCHEME_FILE" ]] || return 0
    mkdir -p "$(dirname "$KDEGLOBALS")"
    python3 - "$SCHEME_FILE" "$KDEGLOBALS" "$ICON_THEME" "$KDE_LNF" <<'PY'
import sys
from pathlib import Path

scheme_path = Path(sys.argv[1])
globals_path = Path(sys.argv[2])
icon_theme = sys.argv[3]
lookandfeel = sys.argv[4]

def parse_ini(path: Path) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}
    current = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip("\n")
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
            groups.setdefault(current, [])
            continue
        if current:
            groups[current].append(line)
    return groups

scheme = parse_ini(scheme_path)
existing = parse_ini(globals_path) if globals_path.is_file() else {}

skip_groups = {
    "General",
    "Icons",
    "KDE",
    "Appearance",
    "WM",
    "KFileDialog Settings",
}
color_groups = [
    name
    for name in scheme
    if name.startswith("Colors:") or name.startswith("ColorEffects:")
]

out: list[str] = []
for name in color_groups:
    out.append(f"[{name}]")
    out.extend(scheme.get(name, []))
    out.append("")

out.append("[General]")
out.append("ColorScheme=Matugen")
out.append("UseSystemBell=true")
out.append("")

out.append("[Icons]")
out.append(f"Theme={icon_theme}")
out.append("")

out.append("[KDE]")
out.append(f"LookAndFeelPackage={lookandfeel}")
out.append("contrast=4")
out.append("widgetStyle=kvantum")
out.append("")

if "WM" in scheme:
    out.append("[WM]")
    out.extend(scheme["WM"])
    out.append("")

if "KFileDialog Settings" in existing:
    out.append("[KFileDialog Settings]")
    out.extend(existing["KFileDialog Settings"])
    out.append("")

globals_path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY
}

ensure_kvantum_theme
sync_kdeglobals

printf '[kde-qt] theme=%s icon=%s lnf=%s kvantum=matugen scheme=%s\n' \
    "$THEME" "$ICON_THEME" "$KDE_LNF" \
    "$( [[ -f "$SCHEME_FILE" ]] && echo Matugen || echo missing )"