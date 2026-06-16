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
# Keeps the SDDM greeter background(s) pointing at your current desktop wallpaper
# using a *central* stable path so multiple themes all see the same "default".
#
# Central image (maintained by set_wallpaper.sh on every waypaper change):
#   ~/.config/settings/default_wp.png
#
# Recommended one-time setup for any SDDM theme (sugar-candy, pixie, eos-breeze, etc.):
#   Background="/home/kirk/.config/settings/default_wp.png"
#   FullBlur="false"
#
# This script (elevated) can also force the above + sync matugen colors into
# the theme.conf files, and ensures the sddm user can read files under $HOME.
#
# Usage:
#   update-sddm-wallpaper.sh [path/to/wallpaper]
#   update-sddm-wallpaper.sh --setup
#
# --setup : One-time action. Run it as your normal user. It will use sudo
#           (preferred) or pkexec to elevate, install a narrow NOPASSWD rule
#           for this script, then perform the update using your real $HOME.

# --- Load your existing helpers for consistent look ---
source "${USER_HOME:-$HOME}/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "${USER_HOME:-$HOME}/.config/hypr/scripts/colors.sh" 2>/dev/null || true

# Without --setup, the script needs root (sudo/pkexec) for writing
# into /usr/share/sddm/themes. The recommended flow is to run
#   ~/.config/hypr/scripts/update-sddm-wallpaper.sh --setup
# as your normal user (it will ask for sudo/pkexec). After that,
# waypaper post-commands can update silently.
# ===================================================================

set -euo pipefail

# --- Self-reexec with privileges if needed (best effort) ---
maybe_elevate() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    SUDOERS_MARKER="/etc/sudoers.d/99-sddm-wallpaper-${REAL_USER:-$USER}"

    # If we have the passwordless sudoers rule (from --setup), prefer sudo -n
    # so the background waypaper call stays completely silent.
    if [ -f "$SUDOERS_MARKER" ]; then
        exec sudo -n -- "$0" "$@"
    fi

    # Prefer sudo (more reliable for these scripts and matches the NOPASSWD rule we create).
    # pkexec can fail with "Not authorized" on some systems (PolicyKit restrictions, KDE, etc.).
    if command -v sudo >/dev/null 2>&1; then
        exec sudo "$0" "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        exec pkexec "$0" "$@"
    else
        echo "ERROR: Neither sudo nor pkexec available to elevate." >&2
        echo "Try:  sudo $0 $*" >&2
        exit 1
    fi
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
    SCRIPT_USER_VISIBLE="$USER_HOME/.config/hypr/scripts/update-sddm-wallpaper.sh"

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

# If not root at this point, try to elevate (pkexec/sudo will re-exec us)
if [ "$EUID" -ne 0 ]; then
    maybe_elevate "$@"
fi


# --- Resolve source wallpaper ---
# Always look under the *real* user's home (even if we are root right now).
if [ -n "${1:-}" ] && [ "$1" != "--setup" ]; then
    SOURCE="$1"
elif [ -f "$USER_HOME/.config/last_wallpaper.txt" ]; then
    SOURCE=$(cat "$USER_HOME/.config/last_wallpaper.txt" | tr -d '\n\r')
elif [ -f "$USER_HOME/.config/settings/default" ]; then
    SOURCE=$(cat "$USER_HOME/.config/settings/default" | tr -d '\n\r')
else
    echo "No wallpaper source available (looked in $USER_HOME/.config/settings/...)" >&2
    notify-send "SDDM Wallpaper" "Failed: no current wallpaper in cache" -u critical 2>/dev/null || true
    exit 1
fi

# Central stable location (the one you point all theme.confs at).
# set_wallpaper.sh already maintains this, but we defensively refresh it here too
# (this part runs as root when elevated, but the file is user-owned).
CENTRAL_DEFAULT="$USER_HOME/.config/settings/default_wp.png"

THEME_DIR="/usr/share/sddm/themes/sugar-candy"
TARGET_DIR="$THEME_DIR/Backgrounds"
TARGET_FILE="$TARGET_DIR/sddm-wallpaper.png"   # kept for compat / old references
THEME_CONF="$THEME_DIR/theme.conf"
OLD_BLURRED="$TARGET_DIR/sddm-blurred.png"

if [ ! -f "$SOURCE" ]; then
    echo "Source wallpaper not found: $SOURCE" >&2
    notify-send "SDDM Wallpaper" "Failed: source not found ($SOURCE)" -u critical 2>/dev/null || true
    exit 1
fi

echo ":: Source: $SOURCE"
echo ":: Ensuring central default: $CENTRAL_DEFAULT"

# Refresh the central canonical image (PNG normalized). This is what SDDM themes read.
if command -v magick >/dev/null 2>&1; then
    magick "$SOURCE" -strip -quality 92 "$CENTRAL_DEFAULT" 2>/dev/null || cp -f "$SOURCE" "$CENTRAL_DEFAULT"
else
    cp -f "$SOURCE" "$CENTRAL_DEFAULT"
fi
chmod 644 "$CENTRAL_DEFAULT" 2>/dev/null || true
# Make sure the real user owns the central image (we may have created it while root)
chown "$REAL_USER:$REAL_USER" "$CENTRAL_DEFAULT" 2>/dev/null || true

# Also keep the per-sugar-candy copy (harmless, some people may still reference it directly)
if [ -d "$THEME_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    if command -v magick >/dev/null 2>&1; then
        magick "$SOURCE" -quality 92 "$TARGET_FILE" 2>/dev/null || cp -f "$SOURCE" "$TARGET_FILE"
    else
        cp -f "$SOURCE" "$TARGET_FILE"
    fi
    chmod 644 "$TARGET_FILE" 2>/dev/null || true
    echo ":: Also updated per-theme copy: $TARGET_FILE (for compat)"
fi

# Allow sddm user to traverse the real user's home and the settings dir
# (needed to read the central default_wp.png even when ~ is 700).
if id sddm >/dev/null 2>&1; then
    setfacl -m u:sddm:x "$USER_HOME" 2>/dev/null || true
    setfacl -m u:sddm:x "$USER_HOME/.config" 2>/dev/null || true
    setfacl -m u:sddm:x "$USER_HOME/.config/settings" 2>/dev/null || true
fi

# Update theme.conf(s) to point at the *central* stable default (so multiple themes
# all follow the same file that gets updated on wallpaper changes).
# We set an absolute path so it works even when the theme is in /usr/share.
CENTRAL_BG="$USER_HOME/.config/settings/default_wp.png"

if [ -f "$THEME_CONF" ]; then
    # Point at the central canonical wallpaper (the key change for "same path, file updates")
    sed -i "s|^Background=.*|Background=\"${CENTRAL_BG}\"|" "$THEME_CONF"

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

    echo ":: theme.conf updated → Background=${CENTRAL_BG} (FullBlur=false)"
fi

# If you use *other* SDDM themes and want this script to also fix their Background=
# lines to the same central path, add more THEME_CONF=... + sed blocks here (or
# generalize with a list of theme dirs). Example:
# OTHER_THEME_CONF="/usr/share/sddm/themes/your-other-theme/theme.conf"
# [ -f "$OTHER_THEME_CONF" ] && sed -i "s|^Background=.*|Background=\"${CENTRAL_BG}\"|" "$OTHER_THEME_CONF" || true

# Remove any leftover legacy blurred SDDM background (we use the raw wallpaper instead)
if [ -f "$OLD_BLURRED" ]; then
    rm -f "$OLD_BLURRED"
    echo ":: Removed legacy sddm-blurred.png (no longer referenced)"
fi

WALL_NAME=$(basename "$SOURCE")
echo ":: SDDM now uses central default: $CENTRAL_DEFAULT"
echo ":: (current image from: $WALL_NAME — takes effect on next login)"
notify-send "SDDM" "Login wallpaper → $WALL_NAME (central default)" -t 2500 2>/dev/null || true
