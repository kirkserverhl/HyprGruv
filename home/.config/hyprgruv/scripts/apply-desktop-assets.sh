#!/usr/bin/env bash
# apply-desktop-assets.sh — GTK/Qt/KDE desktop chrome (themes, icons, cursors)
#
# Usage: apply-desktop-assets.sh [theme-name]
#   theme-name defaults to ~/.config/colorschemes/.current-theme (fallback: gruvbox-dark)

set -euo pipefail

THEME="${1:-}"
COLORSCHEMES_DIR="${HOME}/.config/colorschemes"
GTK3_SETTINGS="${HOME}/.config/gtk-3.0/settings.ini"
QT5CT_CONF="${HOME}/.config/qt5ct/qt5ct.conf"
QT6CT_CONF="${HOME}/.config/qt6ct/qt6ct.conf"
CURSOR_CONF="${HOME}/.config/hypr/conf/cursor.conf"
CURSOR_SIZE="${DESKTOP_CURSOR_SIZE:-24}"
SYNC_KDE_QT="${HOME}/.config/hyprgruv/scripts/sync-kde-qt-theme.sh"

# shellcheck source=/dev/null
source "$COLORSCHEMES_DIR/theme-assets.sh"

if [[ -z "$THEME" && -f "$COLORSCHEMES_DIR/.current-theme" ]]; then
    THEME=$(tr -d '[:space:]' <"$COLORSCHEMES_DIR/.current-theme")
fi
[[ -n "$THEME" ]] || THEME="gruvbox-dark"

FAMILY=$(resolve_theme_family "$THEME")
THEME_DIR="$COLORSCHEMES_DIR/$FAMILY"

GTK_THEME=$(resolve_gtk_theme "$THEME")
ICON_THEME=$(resolve_icon_theme "$THEME")
CURSOR_THEME=$(resolve_cursor_theme "$THEME")
KDE_LNF=$(resolve_kde_lookandfeel "$THEME")

update_gtk3_setting() {
    local key="$1"
    local value="$2"
    [[ -f "$GTK3_SETTINGS" ]] || return 0
    if grep -q "^${key}=" "$GTK3_SETTINGS"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$GTK3_SETTINGS"
    else
        printf '%s=%s\n' "$key" "$value" >>"$GTK3_SETTINGS"
    fi
}

link_gtk4_assets() {
    local src="$THEME_DIR/gtk-4.0"
    local dst="${HOME}/.config/gtk-4.0"
    [[ -d "$src" ]] || return 0
    mkdir -p "$dst"
    ln -sf "$src/gtk.css" "$dst/gtk.css"
    ln -sf "$src/gtk-dark.css" "$dst/gtk-dark.css"
    ln -sfn "$src/assets" "$dst/assets"
}

apply_gsettings() {
    local schema="org.gnome.desktop.interface"
    command -v gsettings >/dev/null 2>&1 || return 0
    gsettings set "$schema" color-scheme "prefer-dark" 2>/dev/null || true
    gsettings set "$schema" gtk-theme "" 2>/dev/null || true
    gsettings set "$schema" gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set "$schema" icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set "$schema" cursor-theme "$CURSOR_THEME" 2>/dev/null || true
}

apply_hypr_cursor() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    if [[ -f "$CURSOR_CONF" ]]; then
        printf 'exec-once = hyprctl setcursor %s %s\n' "$CURSOR_THEME" "$CURSOR_SIZE" >"$CURSOR_CONF"
    fi
    hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" 2>/dev/null || true
}

update_qtct_icon_theme() {
    local conf="$1"
    local icon="$2"
    [[ -f "$conf" ]] || return 0
    if grep -q '^icon_theme=' "$conf"; then
        sed -i "s|^icon_theme=.*|icon_theme=${icon}|" "$conf"
    fi
}

mkdir -p "$(dirname "$GTK3_SETTINGS")"
touch "$GTK3_SETTINGS"

update_gtk3_setting gtk-theme-name "$GTK_THEME"
update_gtk3_setting gtk-icon-theme-name "$ICON_THEME"
update_gtk3_setting gtk-cursor-theme-name "$CURSOR_THEME"
update_gtk3_setting gtk-cursor-theme-size "$CURSOR_SIZE"
update_gtk3_setting gtk-application-prefer-dark-theme "true"

update_qtct_icon_theme "$QT5CT_CONF" "$ICON_THEME"
update_qtct_icon_theme "$QT6CT_CONF" "$ICON_THEME"

link_gtk4_assets
apply_gsettings
apply_hypr_cursor

if [[ -x "$SYNC_KDE_QT" ]]; then
    "$SYNC_KDE_QT" "$THEME" "$ICON_THEME" "$KDE_LNF" 2>/dev/null || true
fi

if [[ -x "${HOME}/.config/hyprgruv/scripts/reload-gtk-colors.sh" ]]; then
    "${HOME}/.config/hyprgruv/scripts/reload-gtk-colors.sh" >/dev/null 2>&1 || true
fi

printf '[desktop-assets] theme=%s family=%s gtk=%s icon=%s cursor=%s kde_lnf=%s\n' \
    "$THEME" "$FAMILY" "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$KDE_LNF"