#!/usr/bin/env bash
# wallpaper-preset-scope.sh — when a wallpaper should use static preset colors
#
# Preset themes (gruvbox-dark, etc.) keep a fixed palette, but waypaper often
# picks from ~/Wallpapers outside the theme folder. Those picks should still
# show the matugen source-color chooser (rofi / palette.sh), not skip it.

wallpaper_in_preset_scope() {
    local wp="${1:-}"
    local wp_real theme theme_dir theme_dir_real

    if [[ -z "$wp" || ! -f "$wp" ]]; then
        return 1
    fi

    wp_real=$(readlink -f "$wp" 2>/dev/null || echo "$wp")

    # dipc / theme-filtered outputs always use wal sync, never Material You chooser
    if [[ "$wp_real" == *"/themed-wallpapers/"* ]]; then
        return 0
    fi

    [[ -f "$HOME/.config/colorschemes/.use-preset-colors" ]] || return 1
    [[ -f "$HOME/.config/colorschemes/.current-theme" ]] || return 1

    theme=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme")
    [[ -n "$theme" ]] || return 1

    # shellcheck source=/dev/null
    source "$HOME/.config/colorschemes/wallpaper-dir.sh" 2>/dev/null || true
    theme_dir=$(resolve_wallpaper_dir "$theme" 2>/dev/null || true)
    if [[ -n "$theme_dir" && -d "$theme_dir" ]]; then
        theme_dir_real=$(readlink -f "$theme_dir" 2>/dev/null || echo "$theme_dir")
        [[ "$wp_real" == "$theme_dir_real"/* ]] && return 0
    fi

    return 1
}