#!/bin/bash
# Shared helpers for colorscheme theme assets.

resolve_custom_asset() {
    local theme="$1"
    case "$theme" in
        catppuccin) printf '%s\n' "catppuccin-mocha" ;;
        nord-darker) printf '%s\n' "nord" ;;
        noir) printf '%s\n' "monochrome" ;;
        *) printf '%s\n' "$theme" ;;
    esac
}

get_source_color() {
    local theme="$1"
    local theme_dir="$HOME/.config/colorschemes/$theme"
    local asset css color

    if [[ -f "$theme_dir/source-color" ]]; then
        color=$(tr -d '[:space:]' <"$theme_dir/source-color")
        [[ "$color" != \#* ]] && color="#$color"
        printf '%s\n' "$color"
        return 0
    fi

    asset="$(resolve_custom_asset "$theme")"
    css="$HOME/Documents/hyprcourse/meridian/.config/waybar/colors/custom/${asset}.css"
    if [[ -f "$css" ]]; then
        color=$(grep '@define-color blue' "$css" | head -1 | sed -E 's/.*#\s*([0-9a-fA-F]{6}).*/#\1/i')
        if [[ -n "$color" ]]; then
            printf '%s\n' "$color"
            return 0
        fi
    fi

    printf '%s\n' "#458588"
}