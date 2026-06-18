#!/usr/bin/env bash
# Shared square-grid rofi picker for HyprGruv Settings menus.

hyprgruv_rofi_grid_dims() {
    local n=$1
    local cols=2

    while (( cols * cols < n )); do
        ((cols++))
    done
    (( cols > 3 )) && cols=3

    local lines=$(( (n + cols - 1) / cols ))
    printf '%s %s' "$cols" "$lines"
}

# hyprgruv_rofi_pick PROMPT "label|icon|id" ...
hyprgruv_rofi_pick() {
    local prompt="$1"
    shift
    local n=$#
    local cols lines width cell=132
    local input="" chosen=""
    local icons_dir="${HYPRGRUV_ICONS_DIR:-$HOME/.config/hyprgruv-settings/icons}"
    local rofi_config="${HYPRGRUV_ROFI_CONFIG:-$HOME/.config/rofi/config-settings.rasi}"

    if ! command -v rofi >/dev/null 2>&1; then
        notify-send -u critical "HyprGruv Settings" "rofi not found in PATH"
        return 1
    fi

    read -r cols lines < <(hyprgruv_rofi_grid_dims "$n")
    width=$(( cols * cell + 56 ))

    for entry in "$@"; do
        IFS='|' read -r label icon _ <<< "$entry"
        input+="${label}\0icon\x1f${icons_dir}/${icon}.png\n"
    done

    if ! chosen=$(
        printf '%b' "$input" | rofi -dmenu -i -show-icons \
            -config "$rofi_config" \
            -p "$prompt" \
            -theme-str "window { width: ${width}px; } listview { columns: ${cols}; lines: ${lines}; }" \
            2>/dev/null
    ); then
        return 1
    fi

    printf '%s' "$chosen"
}