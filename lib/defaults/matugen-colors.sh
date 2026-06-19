#!/usr/bin/env bash
# Pre-matugen / offline fallback — Gruvbox is the standard baseline theme.
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gruvbox-colors.sh"
export MATUGEN_THEME_ACTIVE=0