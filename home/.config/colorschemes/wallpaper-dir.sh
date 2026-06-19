#!/bin/bash
# Resolve wallpaper directory for a colorscheme theme name.

resolve_wallpaper_dir() {
    local theme="$1"
    local folder="$theme"
    local themed_root=""
    local dir=""

    case "$theme" in
        nord-darker) folder="nord" ;;
    esac

    for themed_root in \
        "$HOME/Wallpapers/themed-wallpapers" \
        "$HOME/wallpapers/themed-wallpapers"; do
        dir="$themed_root/$folder"
        if [ -d "$dir" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
    done

    dir="$HOME/.config/colorschemes/$theme/wallpapers"
    if [ -d "$dir" ]; then
        printf '%s\n' "$dir"
        return 0
    fi

    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_wallpaper_dir "$1"
fi