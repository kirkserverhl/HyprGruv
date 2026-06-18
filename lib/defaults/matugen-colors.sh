#!/usr/bin/env bash
# Bundled default matugen palette (opening wallpaper / pre-first-run).
# Matches home/.config/hypr/colors/custom/matugen.conf in the repo.
# Sourced by lib/common.sh when ~/.cache/matugen/colors.sh does not exist yet.

export MATUGEN_THEME_ACTIVE=0
export COLOR_BACKGROUND="#141318"
export COLOR_ON_BACKGROUND="#e5e1e9"
export COLOR_PRIMARY="#c7bfff"
export COLOR_ON_PRIMARY="#2f295f"
export COLOR_PRIMARY_CONTAINER="#463f77"
export COLOR_ON_PRIMARY_CONTAINER="#e4dfff"
export COLOR_SECONDARY="#c8c3dc"
export COLOR_ON_SECONDARY="#302e41"
export COLOR_SURFACE="#141318"
export COLOR_ON_SURFACE="#e5e1e9"
export COLOR_SURFACE_VARIANT="#47464f"
export COLOR_ON_SURFACE_VARIANT="#c9c5d0"
export COLOR_SURFACE_CONTAINER="#201f25"
export COLOR_SURFACE_CONTAINER_HIGH="#2a292f"
export COLOR_SURFACE_CONTAINER_HIGHEST="#35343a"
export COLOR_OUTLINE="#928f99"
export COLOR_OUTLINE_VARIANT="#47464f"
export COLOR_ERROR="#ffb4ab"
export COLOR_ON_ERROR="#690005"
export COLOR_TERTIARY="#ecb8ce"
export COLOR_ON_TERTIARY="#482537"
export COLOR_TERTIARY_CONTAINER="#613b4d"
export COLOR_ACCENT="${COLOR_PRIMARY}"
export COLOR_BG="${COLOR_SURFACE}"
export COLOR_FG="${COLOR_ON_SURFACE}"
export COLOR_TEXT="${COLOR_ON_SURFACE}"