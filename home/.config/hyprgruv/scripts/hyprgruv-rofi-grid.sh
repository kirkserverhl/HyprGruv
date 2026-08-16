#!/usr/bin/env bash
# Shared square-grid rofi picker for HyprGruv Settings menus.

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hyprgruv-rofi-mnemonics.sh"

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

hyprgruv_rofi_icon_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        local theme
        theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
        if [[ -n "$theme" && "$theme" != "null" ]]; then
            printf '%s' "$theme"
            return 0
        fi
    fi

    local gtk_ini="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
    if [[ -f "$gtk_ini" ]]; then
        local theme
        theme=$(grep -E '^gtk-icon-theme-name=' "$gtk_ini" | head -1 | cut -d= -f2-)
        if [[ -n "$theme" ]]; then
            printf '%s' "$theme"
            return 0
        fi
    fi

    printf '%s' 'Gruvbox-Plus-Dark'
}

hyprgruv_rofi_theme_has_icon() {
    local icon="$1"
    local theme="$2"
    local base found

    for base in "${XDG_DATA_HOME:-$HOME/.local/share}/icons" "$HOME/.icons" /usr/share/icons; do
        [[ -d "$base/$theme" ]] || continue
        found=$(find "$base/$theme" \( -iname "${icon}.svg" -o -iname "${icon}.png" \) -print -quit 2>/dev/null)
        if [[ -n "$found" ]]; then
            return 0
        fi
    done

    return 1
}

# Prefer GTK icon-theme names; fall back to generated PNG placeholders.
hyprgruv_rofi_resolve_icon() {
    local icon="$1"
    local fallback_id="$2"
    local icons_dir="$3"
    local theme="$4"

    if [[ "$icon" == /* || -f "$icon" ]]; then
        printf '%s' "$icon"
        return 0
    fi

    if hyprgruv_rofi_theme_has_icon "$icon" "$theme"; then
        printf '%s' "$icon"
        return 0
    fi

    if [[ -f "${icons_dir}/${fallback_id}.png" ]]; then
        printf '%s' "${icons_dir}/${fallback_id}.png"
        return 0
    fi

    printf '%s' "$icon"
}

# hyprgruv_rofi_pick PROMPT "label|icon|id" ...
# Prints the original label (no pango). Letter keys select that row.
hyprgruv_rofi_pick() {
    local prompt="$1"
    shift
    local n=$#
    local cols lines width cell=132
    local input="" chosen="" rc=0
    local icons_dir="${HYPRGRUV_ICONS_DIR:-$HOME/.config/hyprgruv-settings/icons}"
    local rofi_config="${HYPRGRUV_ROFI_CONFIG:-$HOME/.config/rofi/config-settings.rasi}"
    local icon_theme
    local -a labels=() icons=() fallbacks=()
    icon_theme=$(hyprgruv_rofi_icon_theme)

    if ! command -v rofi >/dev/null 2>&1; then
        notify-send -u critical "HyprGruv Settings" "rofi not found in PATH"
        return 1
    fi

    read -r cols lines < <(hyprgruv_rofi_grid_dims "$n")
    width=$(( cols * cell + 56 ))

    local entry label icon fallback_id resolved_icon i
    for entry in "$@"; do
        IFS='|' read -r label icon fallback_id <<< "$entry"
        labels+=("$label")
        icons+=("$icon")
        fallbacks+=("$fallback_id")
    done

    hyprgruv_rofi_assign_mnemonics "${labels[@]}"
    hyprgruv_rofi_bind_mnemonics

    for i in "${!labels[@]}"; do
        resolved_icon=$(hyprgruv_rofi_resolve_icon "${icons[$i]}" "${fallbacks[$i]}" "$icons_dir" "$icon_theme")
        input+="${HYPRGRUV_ROFI_MARKUP[$i]}\0icon\x1f${resolved_icon}\n"
    done

    chosen=$(
        printf '%b' "$input" | rofi -dmenu -i -show-icons \
            -icon-theme "$icon_theme" \
            -config "$rofi_config" \
            -p "$prompt" \
            -theme-str "window { width: ${width}px; } listview { columns: ${cols}; lines: ${lines}; }" \
            "${HYPRGRUV_ROFI_KB_ARGS[@]}" \
            2>/dev/null
    ) || rc=$?

    hyprgruv_rofi_choice_from_exit "$rc" "$chosen" "${labels[@]}"
}