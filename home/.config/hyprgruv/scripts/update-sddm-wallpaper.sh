#!/bin/bash
# --- Determine the real desktop user + home (critical when the script
#     is invoked via sudo, pkexec, or when ~/.config is a symlink into
#     a dotfiles checkout like .hyprgruv). We need the *real* $HOME for
#     finding current_wallpaper / default / matugen colors, etc.
if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="${USER}"
fi

if command -v getent >/dev/null 2>&1; then
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null || true)
fi
: "${REAL_HOME:=$HOME}"
USER_HOME="$REAL_HOME"

# ===================================================================
# update-sddm-wallpaper.sh
#
# Copies or converts the current waypaper wallpaper into the sugar-candy theme:
#   /usr/share/sddm/themes/sugar-candy/sddm-wallpaper.png
#
# Non-PNG sources are converted with ImageMagick. PNG sources are hard-copied.
# theme.conf Background= is kept pointed at that path, and matugen colors are synced.
#
# Triggered automatically from waypaper via set_wallpaper.sh (post_command).
# Runs as your user — no sudo prompt. (Your sugar-candy theme dir is user-owned.)
#
# Usage:
#   update-sddm-wallpaper.sh [path/to/wallpaper]
#   update-sddm-wallpaper.sh --setup   # optional legacy NOPASSWD rule if theme is root-owned

# --- Load your existing helpers for consistent look ---
source "${USER_HOME:-$HOME}/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "${USER_HOME:-$HOME}/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
# ===================================================================

set -euo pipefail

THEME_DIR="/usr/share/sddm/themes/sugar-candy"

theme_is_writable() {
    [ -d "$THEME_DIR" ] && [ -w "$THEME_DIR" ]
}

maybe_elevate() {
    [ "$EUID" -eq 0 ] && return 0
    theme_is_writable && return 0

    SUDOERS_MARKER="/etc/sudoers.d/99-sddm-wallpaper-${REAL_USER:-$USER}"
    if [ -f "$SUDOERS_MARKER" ] && command -v sudo >/dev/null 2>&1; then
        exec sudo -n -- "$0" "$@"
    fi

    echo "ERROR: Cannot write to $THEME_DIR (not writable and no passwordless sudo rule)." >&2
    echo "Fix ownership: sudo chown -R ${REAL_USER}:${REAL_USER} $THEME_DIR" >&2
    echo "Or run once: $0 --setup" >&2
    exit 1
}

# Handle --setup (one-time). We prefer that you run this *without* an
# outer sudo, i.e. as your normal user. The block below will request
# elevation itself so that SUDO_USER is populated correctly.
if [ "${1:-}" = "--setup" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo ":: Requesting privileges for initial SDDM wallpaper setup..."
        # Prefer sudo for reliability (especially on setups where pkexec/PolicyKit
        # is restrictive or the GUI auth agent denies the action). sudo is what
        # we will use for the NOPASSWD rule anyway.
        if command -v sudo >/dev/null 2>&1; then
            exec sudo "$0" "$@"
        elif command -v pkexec >/dev/null 2>&1; then
            exec pkexec "$0" "$@"
        else
            echo "ERROR: Neither sudo nor pkexec found. Please run manually with:" >&2
            echo "  sudo $0 --setup" >&2
            exit 1
        fi
    fi

    # We are now root. SUDO_USER (if present) tells us who the real desktop user is.
    SETUP_FOR_USER="${SUDO_USER:-$REAL_USER}"
    if [ -z "$SETUP_FOR_USER" ] || [ "$SETUP_FOR_USER" = "root" ]; then
        echo "ERROR: Could not determine the desktop user for the sudoers rule (SUDO_USER=$SUDO_USER REAL_USER=$REAL_USER)." >&2
        echo "Try running as your normal user (no outer sudo):  $0 --setup" >&2
        exit 1
    fi

    SUDOERS_FILE="/etc/sudoers.d/99-sddm-wallpaper-${SETUP_FOR_USER}"

    echo ":: Setting up passwordless SDDM wallpaper updates for user '$SETUP_FOR_USER'..."

    # Resolve the *real* on-disk path (follows symlinks into e.g. .hyprgruv checkouts)
    SCRIPT_REAL=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")

    # The path the user will normally invoke from (what set_wallpaper.sh and waypaper use)
    SCRIPT_USER_VISIBLE="$USER_HOME/.config/hyprgruv/scripts/update-sddm-wallpaper.sh"

    # Create rules for *both* (covers symlink vs realpath cases common in dotfiles/stow setups)
    TMP=$(mktemp)
    {
        echo "${SETUP_FOR_USER} ALL=(root) NOPASSWD: ${SCRIPT_REAL}"
        if [ "$SCRIPT_REAL" != "$SCRIPT_USER_VISIBLE" ]; then
            echo "${SETUP_FOR_USER} ALL=(root) NOPASSWD: ${SCRIPT_USER_VISIBLE}"
        fi
    } > "$TMP"

    if visudo -c -f "$TMP" >/dev/null 2>&1; then
        install -m 440 -o root -g root "$TMP" "$SUDOERS_FILE"
        echo ":: Sudoers rule installed: $SUDOERS_FILE"
        echo ":: Allowing: $SCRIPT_REAL"
        [ "$SCRIPT_REAL" != "$SCRIPT_USER_VISIBLE" ] && echo ":: Also allowing: $SCRIPT_USER_VISIBLE"
        rm -f "$TMP"
    else
        echo "ERROR: Generated sudoers rule failed visudo check. Aborting." >&2
        cat "$TMP" >&2
        rm -f "$TMP"
        exit 1
    fi

    # Shift --setup away and fall through as root to do the actual privileged update.
    # Source resolution below will use the correct USER_HOME.
    shift
fi

maybe_elevate "$@"

expand_path() {
    local p="${1//\"/}"
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    # Use ${p:2} not ${p#~/} — bash expands ~ in the prefix pattern and breaks paths.
    if [[ "$p" == "~/"* ]]; then
        printf '%s\n' "$USER_HOME/${p:2}"
    elif [[ "$p" == "~" ]]; then
        printf '%s\n' "$USER_HOME"
    else
        printf '%s\n' "$p"
    fi
}

read_waypaper_wallpaper() {
    local ini="$USER_HOME/.config/waypaper/config.ini" line
    [ -f "$ini" ] || return 1
    line=$(grep -m1 '^wallpaper[[:space:]]*=[[:space:]]*' "$ini" 2>/dev/null | cut -d= -f2- || true)
    [ -n "$line" ] || return 1
    expand_path "$line"
}

# --- Resolve source wallpaper (waypaper config is the source of truth) ---
if [ -n "${1:-}" ] && [ "$1" != "--setup" ]; then
    SOURCE=$(expand_path "$1")
elif wp=$(read_waypaper_wallpaper); then
    SOURCE="$wp"
elif [ -f "$USER_HOME/.config/last_wallpaper.txt" ]; then
    SOURCE=$(expand_path "$(cat "$USER_HOME/.config/last_wallpaper.txt" | tr -d '\n\r')")
elif [ -f "$USER_HOME/.config/settings/default" ]; then
    SOURCE=$(expand_path "$(cat "$USER_HOME/.config/settings/default" | tr -d '\n\r')")
else
    echo "No wallpaper source available (looked in $USER_HOME/.config/waypaper/config.ini)" >&2
    notify-send "SDDM Wallpaper" "Failed: no current wallpaper in cache" -u critical 2>/dev/null || true
    exit 1
fi

# User-local canonical copy (hyprlock, wlogout, etc. — maintained by set_wallpaper.sh).
CENTRAL_DEFAULT="$USER_HOME/.config/settings/default_wp.png"

TARGET_FILE="$THEME_DIR/sddm-wallpaper.png"
THEME_CONF="$THEME_DIR/theme.conf"
LEGACY_TARGET="$THEME_DIR/Backgrounds/sddm-wallpaper.png"
OLD_BLURRED="$THEME_DIR/Backgrounds/sddm-blurred.png"

# Install waypaper's current wallpaper into the sugar-candy theme folder.
# PNG sources are hard-copied (fast, no re-encode). Other formats are converted to PNG.
ensure_sddm_qt6_compat() {
    local qml meta
    for qml in "$THEME_DIR"/Main.qml "$THEME_DIR"/Components/*.qml; do
        [ -f "$qml" ] || continue
        if grep -q 'import QtGraphicalEffects 1.0' "$qml" 2>/dev/null; then
            sed -i 's|import QtGraphicalEffects 1.0|import Qt5Compat.GraphicalEffects|g' "$qml"
            echo ":: Patched Qt6 compat in $(basename "$qml")"
        fi
    done

    meta="$THEME_DIR/metadata.desktop"
    if [ -f "$meta" ] && ! grep -q '^QtVersion=6' "$meta" 2>/dev/null; then
        echo 'QtVersion=6' >> "$meta"
        echo ":: Set QtVersion=6 in metadata.desktop"
    fi
}

install_sddm_theme_wallpaper() {
    local src="$1" dest="$2"
    local ext="${src##*.}"
    ext="${ext,,}"

    rm -f "$dest"

    if [ "$ext" = "png" ]; then
        cp -f -- "$src" "$dest"
        echo ":: Hard-copied PNG wallpaper → $dest"
        return 0
    fi

    if command -v magick >/dev/null 2>&1; then
        magick "$src" -strip -interlace none -quality 92 "$dest"
        echo ":: Converted ${ext} → PNG at $dest"
        return 0
    fi

    if command -v convert >/dev/null 2>&1; then
        convert "$src" -strip -quality 92 "$dest"
        echo ":: Converted ${ext} → PNG at $dest (legacy convert)"
        return 0
    fi

    echo "ERROR: Source is .$ext but ImageMagick is not installed for PNG conversion." >&2
    return 1
}

if [ ! -f "$SOURCE" ]; then
    echo "Source wallpaper not found: $SOURCE" >&2
    notify-send "SDDM Wallpaper" "Failed: source not found ($SOURCE)" -u critical 2>/dev/null || true
    exit 1
fi

echo ":: Source: $SOURCE"
echo ":: Ensuring user-local default: $CENTRAL_DEFAULT"

# Keep the user-local canonical PNG in sync (non-fatal if this fails).
if command -v magick >/dev/null 2>&1; then
    magick "$SOURCE" -strip -interlace none -quality 92 "$CENTRAL_DEFAULT" 2>/dev/null \
        || cp -f -- "$SOURCE" "$CENTRAL_DEFAULT"
else
    cp -f -- "$SOURCE" "$CENTRAL_DEFAULT"
fi
chmod 644 "$CENTRAL_DEFAULT" 2>/dev/null || true
[ "$EUID" -eq 0 ] && chown "$REAL_USER:$REAL_USER" "$CENTRAL_DEFAULT" 2>/dev/null || true

if [ -d "$THEME_DIR" ]; then
    ensure_sddm_qt6_compat
    install_sddm_theme_wallpaper "$SOURCE" "$TARGET_FILE"
    chmod 644 "$TARGET_FILE" 2>/dev/null || true
    [ "$EUID" -eq 0 ] && chown "$REAL_USER:$REAL_USER" "$TARGET_FILE" 2>/dev/null || true
fi

# Drop legacy Backgrounds/ copy so only the theme-root path is used.
[ -e "$LEGACY_TARGET" ] && rm -f "$LEGACY_TARGET" && echo ":: Removed legacy $LEGACY_TARGET"

SDDM_BG="$TARGET_FILE"

if [ -f "$THEME_CONF" ]; then
    sed -i "s|^Background=.*|Background=\"${SDDM_BG}\"|" "$THEME_CONF"

    if command -v magick >/dev/null 2>&1; then
        WP_W=$(magick identify -format '%w' "$TARGET_FILE" 2>/dev/null || echo "1920")
        WP_H=$(magick identify -format '%h' "$TARGET_FILE" 2>/dev/null || echo "1080")
        sed -i "s|^ScreenWidth=.*|ScreenWidth=\"${WP_W}\"|" "$THEME_CONF"
        sed -i "s|^ScreenHeight=.*|ScreenHeight=\"${WP_H}\"|" "$THEME_CONF"
    fi

    # Disable full-screen blur; we want the real wallpaper visible
    sed -i 's|^FullBlur=.*|FullBlur="false"|' "$THEME_CONF"

    # Keep cropped scaling (good default for photos/wallpapers)
    sed -i 's|^ScaleImageCropped=.*|ScaleImageCropped="true"|' "$THEME_CONF"

    # Pull current matugen colors (fall back to reasonable dark theme values)
    MATUGEN_CONF="$USER_HOME/.config/hypr/colors/custom/matugen.conf"

    if [ -f "$MATUGEN_CONF" ]; then
        # Extract rgba(...) values and convert to #hex for SDDM
        get_hex() {
            grep -m1 "^\$$1 = rgba(" "$MATUGEN_CONF" 2>/dev/null | sed -E 's/.*rgba\(([0-9a-fA-F]{6}).*/#\1/' || echo "$2"
        }

        MAIN_COLOR=$(get_hex "on_surface" "#e2e2e2")
        ACCENT_COLOR=$(get_hex "primary" "#98ccf9")
        BG_COLOR=$(get_hex "surface_container" "#1f1f1f")

        sed -i "s|^MainColor=.*|MainColor=\"${MAIN_COLOR}\"|" "$THEME_CONF"
        sed -i "s|^AccentColor=.*|AccentColor=\"${ACCENT_COLOR}\"|" "$THEME_CONF"
        sed -i "s|^BackgroundColor=.*|BackgroundColor=\"${BG_COLOR}\"|" "$THEME_CONF"

        # Try to use a font close to what wlogout/hyprlock use
        sed -i 's|^Font=.*|Font="HeavyData Nerd Font"|' "$THEME_CONF"

        echo ":: theme.conf colors + font updated from matugen"
    fi

    echo ":: theme.conf updated → Background=${SDDM_BG} (FullBlur=false)"
fi

# Remove any leftover legacy blurred SDDM background (we use the raw wallpaper instead)
if [ -f "$OLD_BLURRED" ]; then
    rm -f "$OLD_BLURRED"
    echo ":: Removed legacy sddm-blurred.png (no longer referenced)"
fi

WALL_NAME=$(basename "$SOURCE")
echo ":: SDDM sugar-candy wallpaper: $TARGET_FILE"
echo ":: (from: $WALL_NAME — takes effect on next login)"
notify-send "SDDM" "Login wallpaper → $WALL_NAME" -t 2500 2>/dev/null || true
