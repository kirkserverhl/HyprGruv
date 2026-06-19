#!/usr/bin/env bash
# matugen-posthook-firefox.sh — push matugen palette into Firefox via pywalfox

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

"${SCRIPTS}/sync-pywalfox-from-matugen.sh" 2>/dev/null || true

if command -v pywalfox >/dev/null 2>&1; then
    timeout 5 pywalfox update 2>/dev/null || true
fi