#!/usr/bin/env bash
# matugen-posthook-gum.sh — rebuild gum CLI theme from the live system palette
#
# Gum 0.16 has no theme file. Color comes from GUM_* env vars.
# This hook writes:
#   ~/.cache/matugen/colors.sh   (COLOR_* for headers / install)
#   ~/.cache/matugen/gum.env     (GUM_* for confirm / choose / input / spin)
#
# Wired from:
#   matugen [templates.gum] post_hook
#   reload-matugen-visible.sh    (Super+W cache-hit / tailored pass)
#   ~/.local/bin/matugen-posthook
#
# Always re-reads hypr matugen.conf (not the derived shell cache).

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
COLORS_SH="${SCRIPTS}/colors.sh"

[[ -f "$COLORS_SH" ]] || exit 0

export HYPRGRUV_COLORS_SKIP_CACHE=1
# shellcheck source=/dev/null
source "$COLORS_SH" --gum --refresh

if declare -F write_matugen_shell_color_cache >/dev/null 2>&1; then
    write_matugen_shell_color_cache 2>/dev/null || true
fi
if declare -F write_gum_env_cache >/dev/null 2>&1; then
    write_gum_env_cache 2>/dev/null || true
fi
