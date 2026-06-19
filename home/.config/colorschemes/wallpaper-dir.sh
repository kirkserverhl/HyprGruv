#!/bin/bash
# Resolve wallpaper directory for a colorscheme theme name.

_dir_has_images() {
    local dir="$1"
    [[ -d "$dir" ]] || return 1
    find "$dir" -maxdepth 1 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.svg' \) -print -quit | grep -q .
}

resolve_wallpaper_dir() {
    local theme="$1"
    local folder="$theme"
    local themed_root=""
    local dir=""
    local registry="$HOME/.config/colorschemes/themes.registry.json"
    local -a candidates=()

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
        candidates+=("$themed_root/$folder")
    done
    candidates+=("$HOME/.config/colorschemes/$theme/wallpapers")
    if [[ "$folder" != "$theme" ]]; then
        candidates+=("$HOME/.config/colorschemes/$folder/wallpapers")
    fi

    for dir in "${candidates[@]}"; do
        if _dir_has_images "$dir"; then
            printf '%s\n' "$dir"
            return 0
        fi
    done

    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    resolve_wallpaper_dir "$1"
fi