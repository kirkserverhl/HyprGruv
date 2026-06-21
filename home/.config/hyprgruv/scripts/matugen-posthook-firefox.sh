#!/usr/bin/env bash
# matugen-posthook-firefox.sh — push matugen palette into Firefox via pywalfox
#
# PYWALFOX_SKIP_SYNC=1  — matugen template just wrote colors.json; only notify extension
# (default)             — rebuild colors.json from freshest palette cache, then notify

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

if [[ "${PYWALFOX_SKIP_SYNC:-0}" != "1" ]]; then
    "${SCRIPTS}/sync-pywalfox-from-matugen.sh" 2>/dev/null || true
fi

if command -v pywalfox >/dev/null 2>&1; then
    timeout 5 pywalfox update 2>/dev/null || true
fi