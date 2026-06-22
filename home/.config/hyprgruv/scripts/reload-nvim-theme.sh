#!/usr/bin/env bash
# reload-nvim-theme.sh — hot-reload Neovim palette + lualine from matugen-theme.lua
#
# Running nvim instances listen for SIGUSR1 (see ~/.config/nvim/lua/plugins/matugen.lua).

set -euo pipefail

if command -v pgrep >/dev/null 2>&1 && pgrep -x nvim >/dev/null 2>&1; then
    pkill -SIGUSR1 nvim 2>/dev/null || true
fi