#!/usr/bin/env bash
# matugen-posthook-browsers.sh — matugen palette → Chrome + Brave
#
# 1. Symlink ~/.config/brave/matugen-theme.user.css → chrome matugen CSS vars
# 2. Write ~/.config/base16-everything/config.yaml (base24) for Base16 Everything
# 3. Ensure native messaging host manifests are installed

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
CHROME_CSS="${HOME}/.config/chrome/matugen-theme.user.css"
BRAVE_DIR="${HOME}/.config/brave"
BRAVE_CSS="${BRAVE_DIR}/matugen-theme.user.css"

if [[ -x "$SCRIPTS/install-base16-everything-host.sh" ]]; then
    "$SCRIPTS/install-base16-everything-host.sh" 2>/dev/null || true
fi

if [[ -x "$SCRIPTS/sync-base16-everything-from-matugen.py" ]]; then
    python3 "$SCRIPTS/sync-base16-everything-from-matugen.py" 2>/dev/null || true
fi

[[ -f "$CHROME_CSS" ]] || exit 0

mkdir -p "$BRAVE_DIR"

if [[ -L "$BRAVE_CSS" ]]; then
    rm -f "$BRAVE_CSS"
elif [[ -f "$BRAVE_CSS" ]]; then
    cp -f "$BRAVE_CSS" "${BRAVE_CSS}.bak" 2>/dev/null || true
    rm -f "$BRAVE_CSS"
fi

ln -sf "../chrome/matugen-theme.user.css" "$BRAVE_CSS"