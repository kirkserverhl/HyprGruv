#!/bin/bash
# Shared helpers for colorscheme theme assets (palette, GTK, icons, cursors).

# Map theme picker ids / personal variants → canonical desktop asset family.
resolve_theme_family() {
    local theme="$1"
    case "$theme" in
    catppuccin) printf '%s\n' "catppuccin" ;;
    nord-darker | nord) printf '%s\n' "nord-darker" ;;
    everforest-dark | forest-night) printf '%s\n' "everforest-dark" ;;
    gruvbox-dark | coast-gruv | warm-stone) printf '%s\n' "gruvbox-dark" ;;
    gruvbox-light) printf '%s\n' "gruvbox-light" ;;
    noir) printf '%s\n' "noir" ;;
    e-ink) printf '%s\n' "e-ink" ;;
    "")
        printf '%s\n' "gruvbox-dark"
        ;;
    *)
        if [[ -d "$HOME/.config/colorschemes/$theme" ]]; then
            printf '%s\n' "$theme"
        else
            printf '%s\n' "gruvbox-dark"
        fi
        ;;
    esac
}

resolve_custom_asset() {
    local theme="$1"
    case "$(resolve_theme_family "$theme")" in
    catppuccin) printf '%s\n' "catppuccin-mocha" ;;
    nord-darker) printf '%s\n' "nord" ;;
    noir) printf '%s\n' "monochrome" ;;
    *) printf '%s\n' "$(resolve_theme_family "$theme")" ;;
    esac
}

_read_icon_theme_name() {
    local index="$1"
    [[ -f "$index" ]] || return 1
    sed -n 's/^[[:space:]]*Name[[:space:]]*=[[:space:]]*//p' "$index" | head -1 | tr -d '\r'
}

icon_theme_exists() {
    local name="$1"
    [[ -n "$(find_icon_theme_name "$name")" ]]
}

cursor_theme_exists() {
    local name="$1"
    [[ -n "$(find_cursor_theme_name "$name")" ]]
}

find_icon_theme_name() {
    local want="$1"
    local base dir index found
    [[ -n "$want" ]] || return 1
    for base in "$HOME/.local/share/icons" "/usr/share/icons"; do
        [[ -d "$base" ]] || continue
        if [[ -d "$base/$want" && -f "$base/$want/index.theme" ]]; then
            found=$(_read_icon_theme_name "$base/$want/index.theme")
            printf '%s\n' "${found:-$want}"
            return 0
        fi
        for dir in "$base"/*; do
            [[ -d "$dir" ]] || continue
            index="$dir/index.theme"
            [[ -f "$index" ]] || continue
            found=$(_read_icon_theme_name "$index")
            if [[ "$found" == "$want" ]]; then
                printf '%s\n' "$found"
                return 0
            fi
        done
    done
    return 1
}

find_cursor_theme_name() {
    local want="$1"
    local base dir index found
    [[ -n "$want" ]] || return 1
    for base in "$HOME/.local/share/icons" "/usr/share/icons"; do
        [[ -d "$base" ]] || continue
        if [[ -d "$base/$want" && -f "$base/$want/index.theme" ]]; then
            found=$(_read_icon_theme_name "$base/$want/index.theme")
            printf '%s\n' "${found:-$want}"
            return 0
        fi
        for dir in "$base"/*; do
            [[ -d "$dir" ]] || continue
            index="$dir/index.theme"
            [[ -f "$index" ]] || continue
            found=$(_read_icon_theme_name "$index")
            if [[ "$found" == "$want" ]]; then
                printf '%s\n' "$found"
                return 0
            fi
        done
    done
    return 1
}

GTK_THEME_UNUSED_DIR="${GTK_THEME_UNUSED_DIR:-$HOME/.themes/unused}"

gtk_theme_exists() {
    local name="$1"
    local base
    for base in "$HOME/.themes" "$GTK_THEME_UNUSED_DIR" "/usr/share/themes"; do
        [[ -d "$base/$name" ]] && return 0
    done
    return 1
}

# GTK only loads ~/.themes/<name> — symlink from ~/.themes/unused/ when needed.
activate_gtk_theme() {
    local name="$1"
    local src dest current_target

    [[ -n "$name" ]] || return 1
    if [[ -d "$HOME/.themes/$name" ]]; then
        return 0
    fi
    src="$GTK_THEME_UNUSED_DIR/$name"
    [[ -d "$src" ]] || return 1

    dest="$HOME/.themes/$name"
    mkdir -p "$HOME/.themes"
    if [[ -L "$dest" ]]; then
        current_target=$(readlink "$dest" 2>/dev/null || true)
        [[ "$current_target" == "$src" || "$current_target" == "unused/$name" ]] && return 0
        rm -f "$dest"
    elif [[ -e "$dest" ]]; then
        return 0
    fi
    ln -sfn "$src" "$dest"
    return 0
}

# First existing candidate from a whitespace-separated preference list.
pick_existing_icon_theme() {
    local candidate resolved fallback="Papirus-Dark"
    for candidate in "$@"; do
        resolved=$(find_icon_theme_name "$candidate" 2>/dev/null || true)
        if [[ -n "$resolved" ]]; then
            printf '%s\n' "$resolved"
            return 0
        fi
    done
    resolved=$(find_icon_theme_name "$fallback" 2>/dev/null || true)
    if [[ -n "$resolved" ]]; then
        printf '%s\n' "$resolved"
    else
        printf '%s\n' "hicolor"
    fi
}

pick_existing_cursor_theme() {
    local candidate resolved fallback="Bibata-Modern-Classic-Gruvbox"
    for candidate in "$@"; do
        resolved=$(find_cursor_theme_name "$candidate" 2>/dev/null || true)
        if [[ -n "$resolved" ]]; then
            printf '%s\n' "$resolved"
            return 0
        fi
    done
    resolved=$(find_cursor_theme_name "$fallback" 2>/dev/null || true)
    if [[ -n "$resolved" ]]; then
        printf '%s\n' "$resolved"
    else
        printf '%s\n' "default"
    fi
}

gtk_theme_is_light() {
    local name="${1,,}"
    [[ "$name" == *light* ]]
}

pick_existing_gtk_theme() {
    local candidate fallback="adw-gtk3-dark"
    for candidate in "$@"; do
        [[ -n "$candidate" ]] || continue
        gtk_theme_is_light "$candidate" && continue
        if gtk_theme_exists "$candidate"; then
            activate_gtk_theme "$candidate" >/dev/null 2>&1 || true
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    if gtk_theme_exists "$fallback"; then
        printf '%s\n' "$fallback"
    else
        printf '%s\n' "Adwaita-dark"
    fi
}

_read_gtk_theme_slot() {
    local theme="$1"
    local family slot_file slot_name=""
    family=$(resolve_theme_family "$theme")

    for slot_file in \
        "$HOME/.config/colorschemes/$theme/gtk-theme" \
        "$HOME/.config/colorschemes/$family/gtk-theme"; do
        if [[ -f "$slot_file" ]]; then
            slot_name=$(tr -d '[:space:]' <"$slot_file")
            [[ -n "$slot_name" ]] && break
        fi
    done

    printf '%s\n' "$slot_name"
}

resolve_gtk_theme() {
    local theme="$1"
    local family slot_name
    family=$(resolve_theme_family "$theme")
    slot_name=$(_read_gtk_theme_slot "$theme")

    case "$family" in
    catppuccin)
        pick_existing_gtk_theme "$slot_name" Catppuccin-Dark Gruvbox-Dark adw-gtk3-dark
        ;;
    nord-darker)
        pick_existing_gtk_theme "$slot_name" Nordic-darker Nordic-darker-v40 Gruvbox-Dark adw-gtk3-dark
        ;;
    everforest-dark)
        pick_existing_gtk_theme "$slot_name" Everforest-Dark Gruvbox-Dark adw-gtk3-dark
        ;;
    noir | e-ink)
        pick_existing_gtk_theme "$slot_name" Graphite-Dark-compact Gruvbox-Dark adw-gtk3-dark
        ;;
    gruvbox-dark)
        pick_existing_gtk_theme "$slot_name" Gruvbox-Dark adw-gtk3-dark
        ;;
    gruvbox-light)
        pick_existing_gtk_theme Gruvbox-Dark adw-gtk3-dark
        ;;
    *)
        pick_existing_gtk_theme "$slot_name" Gruvbox-Dark adw-gtk3-dark
        ;;
    esac
}

_read_icon_theme_slot() {
    local theme="$1"
    local family slot_file slot_name=""
    family=$(resolve_theme_family "$theme")

    for slot_file in \
        "$HOME/.config/colorschemes/$theme/icon-theme" \
        "$HOME/.config/colorschemes/$family/icon-theme"; do
        if [[ -f "$slot_file" ]]; then
            slot_name=$(tr -d '[:space:]' <"$slot_file")
            [[ -n "$slot_name" ]] && break
        fi
    done

    printf '%s\n' "$slot_name"
}

resolve_icon_theme() {
    local theme="$1"
    local family slot_name
    family=$(resolve_theme_family "$theme")
    slot_name=$(_read_icon_theme_slot "$theme")

    case "$family" in
    catppuccin)
        pick_existing_icon_theme "$slot_name" Papirus-Dark Ant-Dark Gruvbox-Plus-Dark
        ;;
    nord-darker)
        pick_existing_icon_theme "$slot_name" Zafiro-Nord-Black Papirus-Dark Gruvbox-Plus-Dark
        ;;
    everforest-dark)
        pick_existing_icon_theme "$slot_name" Everforest-Dark Papirus-Dark Gruvbox-Plus-Dark
        ;;
    noir)
        pick_existing_icon_theme "$slot_name" GreyStone Papirus-Dark Gruvbox-Plus-Dark
        ;;
    *)
        pick_existing_icon_theme "$slot_name" Gruvbox-Plus-Dark Papirus-Dark
        ;;
    esac
}

resolve_kde_lookandfeel() {
    local theme="$1"
    local family slot_file slot_name
    family=$(resolve_theme_family "$theme")
    slot_file="$HOME/.config/colorschemes/$family/kde-lookandfeel"
    if [[ -f "$slot_file" ]]; then
        slot_name=$(tr -d '[:space:]' <"$slot_file")
        [[ -n "$slot_name" ]] && printf '%s\n' "$slot_name" && return 0
    fi

    case "$family" in
    nord-darker)
        printf '%s\n' "org.kde.breezedark.desktop"
        ;;
    *)
        printf '%s\n' "Ant-Dark"
        ;;
    esac
}

resolve_cursor_theme() {
    local theme="$1"
    case "$(resolve_theme_family "$theme")" in
    catppuccin)
        pick_existing_cursor_theme Nordzy-catppuccin-mocha-rosewater "Catppuccin Frappé Rosewater" catppuccin-frappe-rosewater-cursors Bibata-Modern-Classic-Gruvbox
        ;;
    nord-darker)
        pick_existing_cursor_theme Nordzy-cursors Nordzy-cursors-white Bibata-Modern-Classic-Gruvbox
        ;;
    everforest-dark)
        pick_existing_cursor_theme Nordzy-cursors Bibata-Modern-Classic-Gruvbox
        ;;
    *)
        pick_existing_cursor_theme Bibata-Modern-Classic-Gruvbox
        ;;
    esac
}

get_source_color() {
    local theme="$1"
    local theme_dir="$HOME/.config/colorschemes/$(resolve_theme_family "$theme")"
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