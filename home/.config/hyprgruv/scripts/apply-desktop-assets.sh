#!/usr/bin/env bash
# apply-desktop-assets.sh — GTK/Qt/KDE desktop chrome (themes, icons, cursors)
#
# Usage: apply-desktop-assets.sh [theme-name]
#   theme-name defaults to ~/.config/colorschemes/.current-theme (fallback: gruvbox-dark)

set -euo pipefail

THEME="${1:-}"
COLORSCHEMES_DIR="${HOME}/.config/colorschemes"
GTK3_SETTINGS="${HOME}/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="${HOME}/.config/gtk-4.0/settings.ini"
QT5CT_CONF="${HOME}/.config/qt5ct/qt5ct.conf"
QT6CT_CONF="${HOME}/.config/qt6ct/qt6ct.conf"
CURSOR_CONF="${HOME}/.config/hypr/conf/cursor.conf"
CURSOR_SIZE="${DESKTOP_CURSOR_SIZE:-24}"
SYNC_KDE_QT="${HOME}/.config/hyprgruv/scripts/sync-kde-qt-theme.sh"
XSETTINGSD_CONF="${HOME}/.config/xsettingsd/xsettingsd.conf"
XSETTINGSD_BIN="${XSETTINGSD_BIN:-xsettingsd}"

# shellcheck source=/dev/null
source "$COLORSCHEMES_DIR/theme-assets.sh"

if [[ -z "$THEME" && -f "$COLORSCHEMES_DIR/.current-theme" ]]; then
    THEME=$(tr -d '[:space:]' <"$COLORSCHEMES_DIR/.current-theme")
fi
[[ -n "$THEME" ]] || THEME="gruvbox-dark"

FAMILY=$(resolve_theme_family "$THEME")
THEME_DIR="$COLORSCHEMES_DIR/$FAMILY"

GTK_THEME=$(resolve_gtk_theme "$THEME")
activate_gtk_theme "$GTK_THEME" >/dev/null 2>&1 || true
ICON_THEME=$(resolve_icon_theme "$THEME")
CURSOR_THEME=$(resolve_cursor_theme "$THEME")
KDE_LNF=$(resolve_kde_lookandfeel "$THEME")

update_gtk_setting() {
    local file="$1"
    local key="$2"
    local value="$3"
    [[ -f "$file" ]] || return 0
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >>"$file"
    fi
}

update_gtk3_setting() {
    update_gtk_setting "$GTK3_SETTINGS" "$1" "$2"
}

update_gtk4_setting() {
    update_gtk_setting "$GTK4_SETTINGS" "$1" "$2"
}

link_gtk4_assets() {
    local src="$COLORSCHEMES_DIR/$THEME/gtk-4.0"
    local dst="${HOME}/.config/gtk-4.0"
    [[ -d "$src" ]] || src="$THEME_DIR/gtk-4.0"
    [[ -d "$src" ]] || return 0
    mkdir -p "$dst"
    ln -sf "$src/gtk.css" "$dst/gtk.css"
    if [[ -f "$src/gtk-dark.css" ]]; then
        ln -sf "$src/gtk-dark.css" "$dst/gtk-dark.css"
    fi
    if [[ -d "$src/assets" ]]; then
        ln -sfn "$src/assets" "$dst/assets"
    fi
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
    mkdir -p "$(dirname "$CURSOR_CONF")"
    printf 'exec-once = hyprctl setcursor %s %s\n' "$CURSOR_THEME" "$CURSOR_SIZE" >"$CURSOR_CONF"
    hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" 2>/dev/null || true
}

install_theme_to_xdg() {
    local theme="$1"
    local src dest
    [[ -n "$theme" ]] || return 0

    for src in \
        "${HOME}/.icons/${theme}" \
        "${HOME}/.local/share/icons/${theme}" \
        "/usr/share/icons/${theme}"; do
        if [[ -d "$src" && -f "$src/index.theme" ]]; then
            mkdir -p "${HOME}/.local/share/icons"
            dest="${HOME}/.local/share/icons/${theme}"
            if [[ "$src" != "$dest" ]]; then
                ln -sfn "$src" "$dest"
            fi
            return 0
        fi
    done
}

sync_xsettingsd() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local cursor_theme="$3"
    local cursor_size="$4"

    mkdir -p "$(dirname "$XSETTINGSD_CONF")"
    cat >"$XSETTINGSD_CONF" <<EOF
Net/ThemeName "${gtk_theme}"
Net/IconThemeName "${icon_theme}"
Gtk/CursorThemeName "${cursor_theme}"
Gtk/CursorThemeSize ${cursor_size}
Net/EnableEventSounds 1
EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
EOF

    if command -v "$XSETTINGSD_BIN" >/dev/null 2>&1; then
        pkill -x "$XSETTINGSD_BIN" 2>/dev/null || true
        sleep 0.1
        nohup "$XSETTINGSD_BIN" -c "$XSETTINGSD_CONF" >/dev/null 2>&1 &
    fi
}

restart_thunar() {
    if ! command -v thunar >/dev/null 2>&1; then
        return 0
    fi
    if pgrep -x thunar >/dev/null 2>&1; then
        pkill -x thunar 2>/dev/null || true
        sleep 0.3
    fi
    nohup thunar >/dev/null 2>&1 &
}

update_qtct_icon_theme() {
    local conf="$1"
    local icon="$2"
    [[ -f "$conf" ]] || return 0
    if grep -q '^icon_theme=' "$conf"; then
        sed -i "s|^icon_theme=.*|icon_theme=${icon}|" "$conf"
    fi
}

mkdir -p "$(dirname "$GTK3_SETTINGS")" "$(dirname "$GTK4_SETTINGS")"
touch "$GTK3_SETTINGS" "$GTK4_SETTINGS"

for setting in gtk-theme-name gtk-icon-theme-name gtk-cursor-theme-name gtk-cursor-theme-size; do
    case "$setting" in
    gtk-theme-name) value="$GTK_THEME" ;;
    gtk-icon-theme-name) value="$ICON_THEME" ;;
    gtk-cursor-theme-name) value="$CURSOR_THEME" ;;
    gtk-cursor-theme-size) value="$CURSOR_SIZE" ;;
    esac
    update_gtk3_setting "$setting" "$value"
    update_gtk4_setting "$setting" "$value"
done
update_gtk3_setting gtk-application-prefer-dark-theme "true"
update_gtk4_setting gtk-application-prefer-dark-theme "true"

update_qtct_icon_theme "$QT5CT_CONF" "$ICON_THEME"
update_qtct_icon_theme "$QT6CT_CONF" "$ICON_THEME"

install_theme_to_xdg "$ICON_THEME"
install_theme_to_xdg "$CURSOR_THEME"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    for icon_dir in \
        "${HOME}/.local/share/icons/${ICON_THEME}" \
        "${HOME}/.icons/${ICON_THEME}" \
        "/usr/share/icons/${ICON_THEME}"; do
        if [[ -d "$icon_dir" ]]; then
            gtk-update-icon-cache -f -t "$icon_dir" 2>/dev/null || true
            break
        fi
    done
fi

link_gtk4_assets
apply_gsettings
apply_hypr_cursor
sync_xsettingsd "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$CURSOR_SIZE"

if [[ -x "$SYNC_KDE_QT" ]]; then
    "$SYNC_KDE_QT" "$THEME" "$ICON_THEME" "$KDE_LNF" 2>/dev/null || true
fi

if [[ -x "${HOME}/.config/hyprgruv/scripts/reload-gtk-colors.sh" ]]; then
    "${HOME}/.config/hyprgruv/scripts/reload-gtk-colors.sh" >/dev/null 2>&1 || true
fi

restart_thunar

printf '[desktop-assets] theme=%s family=%s gtk=%s icon=%s cursor=%s kde_lnf=%s\n' \
    "$THEME" "$FAMILY" "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$KDE_LNF"