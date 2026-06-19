#!/bin/bash
# Resolve wallpaper directory for a colorscheme theme name.

resolve_wallpaper_dir() {
    local theme="$1"
    local folder="$theme"
    local themed_root=""
    local dir=""
    local registry="$HOME/.config/colorschemes/themes.registry.json"

    if [[ -f "$registry" ]] && command -v jq >/dev/null 2>&1; then
        local mapped
        mapped=$(jq -r --arg t "$theme" '.themes[] | select(.id == $t) | .wallpaper_folder // empty' "$registry" 2>/dev/null || true)
        [[ -n "$mapped" ]] && folder="$mapped"
    fi

    case "$theme" in
        nord-darker)
            [[ "$folder" == "$theme" ]] && folder="nord"
            ;;
    esac

    for themed_root in \
        "$HOME/themed-wallpapers" \
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