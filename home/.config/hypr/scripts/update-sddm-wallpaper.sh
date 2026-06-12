#!/bin/bash
# ===================================================================
# update-sddm-wallpaper.sh
#
# Exports/copies the *current raw wallpaper* (from waypaper) as the
# SDDM login background for the sugar-candy theme.
#
# This replaces any old static "sddm-blurred.png" with the actual
# wallpaper you are using on the desktop.
#
# FullBlur is explicitly disabled (no full-screen blur on the greeter).
# PartialBlur (form area only) is left to the theme default.
# ScaleImageCropped is left enabled for proper wallpaper display.
#
# Usage:
#   update-sddm-wallpaper.sh [path/to/wallpaper]
#   update-sddm-wallpaper.sh --setup
#
# --setup : One-time action (run with sudo). Creates a sudoers rule
#           so future calls from waypaper post-command need no password.
#           Then performs the wallpaper update immediately.
#
# Without --setup, the script needs root (sudo/pkexec). The recommended
# flow is to run --setup once, then waypaper changes will update SDDM
# automatically and silently.
# ===================================================================

set -euo pipefail

# --- Self-reexec with privileges if needed (best effort) ---
maybe_elevate() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    SUDOERS_MARKER="/etc/sudoers.d/99-sddm-wallpaper-${USER}"

    # If we have the passwordless sudoers rule (from --setup), prefer sudo -n
    # so the background waypaper call stays completely silent.
    if [ -f "$SUDOERS_MARKER" ]; then
        exec sudo -n -- "$0" "$@"
    fi

    # Otherwise try pkexec first (may show GUI auth dialog), then sudo (may prompt in terminal)
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec "$0" "$@"
    else
        exec sudo "$0" "$@"
    fi
}

# Handle --setup (must be called with elevation the first time)
if [ "${1:-}" = "--setup" ]; then
    SUDOERS_FILE="/etc/sudoers.d/99-sddm-wallpaper-${USER}"

    echo ":: Setting up passwordless SDDM wallpaper updates..."

    # Resolve the *real* absolute path of this script (handles ~, symlinks, $HOME in calls)
    SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")

    # Create the rule (very narrowly scoped to this exact script path)
    RULE="${USER} ALL=(root) NOPASSWD: ${SCRIPT_PATH}"

    # Write via a temp file + visudo check for safety
    TMP=$(mktemp)
    echo "$RULE" > "$TMP"

    if visudo -c -f "$TMP" >/dev/null 2>&1; then
        install -m 440 -o root -g root "$TMP" "$SUDOERS_FILE"
        echo ":: Sudoers rule installed: $SUDOERS_FILE"
        echo ":: Rule: $RULE"
        rm -f "$TMP"
    else
        echo "ERROR: Generated sudoers rule failed visudo check. Aborting." >&2
        rm -f "$TMP"
        exit 1
    fi

    # Now that we have the rule, re-run the normal update path (as root)
    # Shift away the --setup arg
    shift
    # Fall through to the normal logic below (we are still root from the install)
fi

# If not root at this point, try to elevate (pkexec/sudo will re-exec us)
if [ "$EUID" -ne 0 ]; then
    maybe_elevate "$@"
fi


# --- Resolve source wallpaper ---
if [ -n "${1:-}" ] && [ "$1" != "--setup" ]; then
    SOURCE="$1"
elif [ -f "$HOME/.config/settings/cache/current_wallpaper" ]; then
    SOURCE=$(cat "$HOME/.config/settings/cache/current_wallpaper" | tr -d '\n\r')
elif [ -f "$HOME/.config/settings/default" ]; then
    SOURCE=$(cat "$HOME/.config/settings/default" | tr -d '\n\r')
else
    echo "No wallpaper source available" >&2
    notify-send "SDDM Wallpaper" "Failed: no current wallpaper in cache" -u critical 2>/dev/null || true
    exit 1
fi

THEME_DIR="/usr/share/sddm/themes/sugar-candy"
TARGET_DIR="$THEME_DIR/Backgrounds"
TARGET_FILE="$TARGET_DIR/sddm-wallpaper.png"
THEME_CONF="$THEME_DIR/theme.conf"
OLD_BLURRED="$TARGET_DIR/sddm-blurred.png"

if [ ! -f "$SOURCE" ]; then
    echo "Source wallpaper not found: $SOURCE" >&2
    notify-send "SDDM Wallpaper" "Failed: source not found ($SOURCE)" -u critical 2>/dev/null || true
    exit 1
fi

if [ ! -d "$THEME_DIR" ]; then
    echo "sugar-candy theme not found at $THEME_DIR" >&2
    notify-send "SDDM Wallpaper" "Failed: sugar-candy theme missing" -u critical 2>/dev/null || true
    exit 1
fi

echo ":: Updating SDDM background → $TARGET_FILE"
echo ":: Source: $SOURCE"

# We are root here (either via --setup, pkexec, sudo, or NOPASSWD rule)
mkdir -p "$TARGET_DIR"

# Export the raw current wallpaper directly (PNG for best compatibility)
if command -v magick >/dev/null 2>&1; then
    magick "$SOURCE" -quality 92 "$TARGET_FILE" 2>/dev/null || cp -f "$SOURCE" "$TARGET_FILE"
else
    cp -f "$SOURCE" "$TARGET_FILE"
fi

chmod 644 "$TARGET_FILE" 2>/dev/null || true

# Allow sddm user to traverse $HOME (needed if wallpaper lives in ~/Pictures)
if id sddm >/dev/null 2>&1; then
    setfacl -m u:sddm:x "$HOME" 2>/dev/null || true
fi

# Update theme.conf to point at the actual (non-blurred) wallpaper + matugen colors
if [ -f "$THEME_CONF" ]; then
    # Force the raw current wallpaper (never a pre-blurred/legacy variant)
    sed -i 's|^Background=.*|Background="Backgrounds/sddm-wallpaper.png"|' "$THEME_CONF"

    # Disable full-screen blur; use the actual wallpaper image chosen
    sed -i 's|^FullBlur=.*|FullBlur="false"|' "$THEME_CONF"

    # Leave cropped scaling enabled (do not change this behavior)
    sed -i 's|^ScaleImageCropped=.*|ScaleImageCropped="true"|' "$THEME_CONF"

    # Pull current matugen colors (fall back to reasonable dark theme values)
    MATUGEN_CONF="$HOME/.config/hypr/colors/custom/matugen.conf"

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

    echo ":: theme.conf updated to use actual wallpaper (sddm-wallpaper.png, FullBlur=false)"
fi

# Remove any leftover legacy blurred SDDM background (we use the raw wallpaper instead)
if [ -f "$OLD_BLURRED" ]; then
    rm -f "$OLD_BLURRED"
    echo ":: Removed legacy sddm-blurred.png (no longer referenced)"
fi

WALL_NAME=$(basename "$SOURCE")
echo ":: SDDM background updated to '$WALL_NAME' (takes effect on next login)"
notify-send "SDDM" "Login background updated to: $WALL_NAME" -t 2500 2>/dev/null || true
