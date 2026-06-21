#!/usr/bin/env bash
# matugen-posthook-obsidian.sh — sync Obsidian community theme with active system theme

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

"${SCRIPTS}/obsidian-theme.sh" 2>/dev/null || true