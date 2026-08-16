#!/usr/bin/env bash
# apply-bar-size-profile.sh — write machine-local Waybar / Hyprbars sizes
#
# Source of truth: ~/.config/settings/bar-sizes.sh
# Machine:         ~/.config/settings/machine.sh  (or BAR_SIZE_MACHINE)
#
# Usage:
#   apply-bar-size-profile.sh                         # canonical chrome
#   apply-bar-size-profile.sh /path/to/theme.jsonc    # theme-relative height
#
# Writes:
#   ~/.config/settings/bar_*.sh                       # one-liners (gitignored)
#   ~/.local/state/waybar/bar-chrome.jsonc            # height + margins
#   ~/.local/state/waybar/bar-size.css                # CSS variables
#   ~/.config/waybar/shared/bar-size.css              # same, for @import
set -euo pipefail

HOME="${HOME:-}"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/settings"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
WAYBAR_SHARED="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/shared"
SIZES_SH="$SETTINGS_DIR/bar-sizes.sh"
THEME_CFG="${1:-}"

if [[ ! -f "$SIZES_SH" ]]; then
    echo "apply-bar-size-profile: missing $SIZES_SH" >&2
    exit 1
fi

# shellcheck source=/home/kirk/.config/settings/bar-sizes.sh
source "$SIZES_SH"

machine="${BAR_SIZE_MACHINE:-}"
if [[ -z "$machine" && -f "$SETTINGS_DIR/machine.sh" ]]; then
    machine="$(tr -d '[:space:]' <"$SETTINGS_DIR/machine.sh")"
fi
if [[ "$machine" != "laptop" && "$machine" != "desktop" ]]; then
    machine="desktop"
fi

if [[ "$machine" == "laptop" ]]; then
    canon_height="$LAPTOP_BAR_HEIGHT"
    canon_margin_top="$LAPTOP_BAR_MARGIN_TOP"
    canon_margin_x="$LAPTOP_BAR_MARGIN_X"
    font_size="$LAPTOP_FONT_SIZE"
    font_emphasis="$LAPTOP_FONT_SIZE_EMPHASIS"
    font_center="$LAPTOP_FONT_SIZE_CENTER"
    hyprbars_text="$LAPTOP_HYPRBARS_TEXT"
    module_min="$LAPTOP_MODULE_MIN_HEIGHT"
else
    canon_height="$DESKTOP_BAR_HEIGHT"
    canon_margin_top="$DESKTOP_BAR_MARGIN_TOP"
    canon_margin_x="$DESKTOP_BAR_MARGIN_X"
    font_size="$DESKTOP_FONT_SIZE"
    font_emphasis="$DESKTOP_FONT_SIZE_EMPHASIS"
    font_center="$DESKTOP_FONT_SIZE_CENTER"
    hyprbars_text="$DESKTOP_HYPRBARS_TEXT"
    module_min="$DESKTOP_MODULE_MIN_HEIGHT"
fi

jsonc_number() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0
    grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+" "$file" \
        | tail -1 \
        | grep -oE -- '-?[0-9]+$' \
        || true
}

clamp_int() {
    local n="$1" min="$2"
    if [[ -z "$n" ]]; then
        printf '%s\n' "$min"
        return
    fi
    if (( n < min )); then
        printf '%s\n' "$min"
    else
        printf '%s\n' "$n"
    fi
}

# Theme-relative chrome: shrink/grow by the canonical delta so freshstart 36
# becomes 28 on laptop (36 - 32 + 24) instead of snapping every theme to 24.
# Only emit keys the theme already owns (or shared/bar-chrome.jsonc) so
# auto-height themes like subtle keep their own layout on desktop.
height="$canon_height"
margin_top="$canon_margin_top"
margin_x="$canon_margin_x"
uses_shared_chrome=0
write_height=0
write_margin_top=0
write_margin_x=0

if [[ -n "$THEME_CFG" && -f "$THEME_CFG" ]]; then
    grep -q 'shared/bar-chrome\.jsonc' "$THEME_CFG" && uses_shared_chrome=1
    theme_h="$(jsonc_number "$THEME_CFG" height)"
    theme_mt="$(jsonc_number "$THEME_CFG" margin-top)"
    theme_mx="$(jsonc_number "$THEME_CFG" margin-left)"
    if [[ -n "$theme_h" || "$uses_shared_chrome" -eq 1 ]]; then
        write_height=1
        if [[ -n "$theme_h" ]]; then
            if [[ "$machine" == "laptop" ]]; then
                height=$((theme_h - DESKTOP_BAR_HEIGHT + LAPTOP_BAR_HEIGHT))
            else
                height="$theme_h"
            fi
            height="$(clamp_int "$height" 18)"
        fi
    fi
    if [[ -n "$theme_mt" || "$uses_shared_chrome" -eq 1 ]]; then
        write_margin_top=1
        if [[ -n "$theme_mt" ]]; then
            if [[ "$machine" == "laptop" ]]; then
                margin_top=$((theme_mt - DESKTOP_BAR_MARGIN_TOP + LAPTOP_BAR_MARGIN_TOP))
            else
                margin_top="$theme_mt"
            fi
            margin_top="$(clamp_int "$margin_top" 0)"
        fi
    fi
    if [[ -n "$theme_mx" || "$uses_shared_chrome" -eq 1 ]]; then
        write_margin_x=1
        if [[ -n "$theme_mx" ]]; then
            if [[ "$machine" == "laptop" ]]; then
                margin_x=$((theme_mx - DESKTOP_BAR_MARGIN_X + LAPTOP_BAR_MARGIN_X))
            else
                margin_x="$theme_mx"
            fi
            margin_x="$(clamp_int "$margin_x" 0)"
        fi
    fi
else
    write_height=1
    write_margin_top=1
    write_margin_x=1
fi

mkdir -p "$SETTINGS_DIR" "$STATE_DIR" "$WAYBAR_SHARED"

write_setting() {
    printf '%s\n' "$2" >"$SETTINGS_DIR/${1}.sh"
}

# Canonical values for Hyprbars + anything else that reads settings/*.sh
write_setting bar_height "$canon_height"
write_setting bar_margin_top "$canon_margin_top"
write_setting bar_margin_x "$canon_margin_x"
write_setting bar_font_size "$font_size"
write_setting bar_font_size_emphasis "$font_emphasis"
write_setting bar_font_size_center "$font_center"
write_setting bar_text_size "$hyprbars_text"
write_setting bar_module_min_height "$module_min"

chrome="$STATE_DIR/bar-chrome.jsonc"
{
    echo "/* Generated by apply-bar-size-profile.sh — ${machine}"
    echo " * Tune ~/.config/settings/bar-sizes.sh, then re-run this script."
    echo " */"
    echo "{"
    sep=""
    if [[ "$write_margin_top" -eq 1 ]]; then
        printf '%s  "margin-top": %s' "$sep" "$margin_top"
        sep=$',\n'
    fi
    if [[ "$write_margin_x" -eq 1 ]]; then
        printf '%s  "margin-left": %s,\n  "margin-right": %s' "$sep" "$margin_x" "$margin_x"
        sep=$',\n'
    fi
    if [[ "$write_height" -eq 1 ]]; then
        printf '%s  "height": %s' "$sep" "$height"
        sep=$',\n'
    fi
    [[ -n "$sep" ]] && printf '\n'
    echo "}"
} >"$chrome"

# GTK3 (Waybar) has no :root / var(). Emit concrete font-size rules.
# Imported at the top of base.css; later font-size: 0 spacer rules still win.
star_size="$font_size"
center_block=""
if [[ -n "$THEME_CFG" && "$THEME_CFG" == *"/freshstart/"* ]]; then
    star_size="$font_emphasis"
    center_block=$(cat <<EOF

.modules-center,
.modules-center *,
#group-center,
#group-center *,
#workspaces,
#workspaces button,
#custom-special,
#custom-special label,
#custom-special label.module {
  font-size: ${font_center}px;
}
EOF
)
fi
css_body=$(cat <<EOF
/* Generated by apply-bar-size-profile.sh — ${machine}
 * Tune ~/.config/settings/bar-sizes.sh, then re-run this script / launch.sh.
 * GTK3 CSS: no custom properties. Do not use :root or var().
 */
* {
  font-size: ${star_size}px;
}
${center_block}
EOF
)
printf '%s\n' "$css_body" >"$STATE_DIR/bar-size.css"
printf '%s\n' "$css_body" >"$WAYBAR_SHARED/bar-size.css"

echo "bar-size-profile: ${machine}  height=${height} (canonical ${canon_height})  font=${font_size}/${font_emphasis}/${font_center}  hyprbars=${hyprbars_text}"
