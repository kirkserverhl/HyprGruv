#!/bin/bash
# Resolve wallpaper directory for a colorscheme theme name.
# Prefer themed collections, then the flat waypaper library, then repo seeds.

_dir_has_images() {
    local dir="$1"
    [[ -d "$dir" ]] || return 1
    find "$dir" -maxdepth 1 -type f \( \
        -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.svg' \) -print -quit | grep -q .
}

_resolve_waypaper_folder() {
    local folder="$HOME/Pictures/Wallpapers"
    local conf="$HOME/.config/waypaper/config.ini"
    local line raw
    if [[ -f "$conf" ]]; then
        while IFS= read -r line; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ "$line" == folder\ =* ]] || continue
            raw="${line#folder =}"
            raw="${raw#"${raw%%[![:space:]]*}"}"
            raw="${raw%"${raw##*[![:space:]]}"}"
            folder="${raw/#\~/$HOME}"
            break
        done <"$conf"
    fi
    if [[ -d "$folder" ]]; then
        printf '%s\n' "$folder"
        return 0
    fi
    if [[ -d "$HOME/Wallpapers" ]]; then
        printf '%s\n' "$HOME/Wallpapers"
        return 0
    fi
    return 1
}

resolve_wallpaper_dir() {
    local theme="$1"
    local folder="$theme"
    local themed_root=""
    local dir=""
    local registry="$HOME/.config/colorschemes/themes.registry.json"
    local -a candidates=()
    local waypaper=""

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

    # 1) Dedicated themed collections (desktop layout)
    for themed_root in \
        "$HOME/themed-wallpapers" \
        "$HOME/Pictures/Wallpapers/themed-wallpapers" \
        "$HOME/Pictures/themed-wallpapers" \
        "$HOME/Wallpapers/themed-wallpapers" \
        "$HOME/wallpapers/themed-wallpapers"; do
        candidates+=("$themed_root/$folder")
    done

    for dir in "${candidates[@]}"; do
        if _dir_has_images "$dir"; then
            printf '%s\n' "$dir"
            return 0
        fi
    done

    # 2) Flat waypaper library (HyprGruv wallpaper repo / install seed path)
    waypaper="$(_resolve_waypaper_folder 2>/dev/null || true)"
    if [[ -n "$waypaper" ]] && _dir_has_images "$waypaper"; then
        printf '%s\n' "$waypaper"
        return 0
    fi

    # 3) Bundled colorscheme seeds
    candidates=("$HOME/.config/colorschemes/$theme/wallpapers")
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
