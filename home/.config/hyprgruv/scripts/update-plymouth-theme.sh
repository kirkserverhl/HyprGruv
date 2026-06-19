#!/bin/bash
# ===================================================================
# update-plymouth-theme.sh
#
# Generates and installs a Plymouth splash theme using your current
# matugen colors. This gives you a boot splash ("booting in") that
# roughly matches your desktop theme.
#
# Requires Plymouth to be installed and configured (see instructions
# printed by --setup).
#
# Usage:
#   update-plymouth-theme.sh
#   update-plymouth-theme.sh --setup
#
# --setup : One-time (run with sudo). Installs sudoers rule + prints
#           the full set of manual steps you still need (mkinitcpio,
#           GRUB cmdline, etc.).
#
# installed yet — it will just warn.
# ===================================================================

set -euo pipefail

SUDOERS_MARKER="/etc/sudoers.d/99-plymouth-theme-${USER}"
ENABLE_FILE="${HOME}/.config/settings/plymouth-matugen-sync"

# Silent no-op for any automatic caller (legacy post-hooks, etc.).
if [ "${MATUGEN_AUTO_HOOK:-0}" = "1" ] || [ "${PLYMOUTH_QUIET:-0}" = "1" ]; then
    exit 0
fi

# --- Self-reexec with privileges only when passwordless sudo is configured ---
maybe_elevate() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    if [ -f "$SUDOERS_MARKER" ]; then
        exec sudo -n -- "$0" "$@"
    fi

    if [ "${1:-}" = "--setup" ]; then
        echo "Run with sudo for one-time setup: sudo $0 --setup" >&2
        exit 1
    fi

    echo "Plymouth theme sync skipped (run once: $0 --setup)" >&2
    exit 0
}

# --- Load helpers after quiet/auto exits ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

if [ "${1:-}" = "--setup" ]; then
    SUDOERS_FILE="/etc/sudoers.d/99-plymouth-theme-${USER}"

    echo ":: Setting up passwordless Plymouth theme updates..."

    SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")
    RULE="${USER} ALL=(root) NOPASSWD: ${SCRIPT_PATH}"

    TMP=$(mktemp)
    echo "$RULE" > "$TMP"

    if visudo -c -f "$TMP" >/dev/null 2>&1; then
        install -m 440 -o root -g root "$TMP" "$SUDOERS_FILE"
        echo ":: Sudoers rule installed: $SUDOERS_FILE"
        rm -f "$TMP"
    else
        echo "ERROR: Generated sudoers rule failed visudo check." >&2
        rm -f "$TMP"
        exit 1
    fi

    cat <<'INSTRUCTIONS'

================================================================================
  PLYMOUTH + MATUGEN — ONE TIME MANUAL STEPS (you still need to do these)
================================================================================

1. Install the package:
      sudo pacman -S plymouth

2. Edit /etc/mkinitcpio.conf and add 'plymouth' to the HOOKS array.
   Good example (order matters):
      HOOKS=(base udev autodetect microcode modconf kms keyboard keymap
             consolefont block filesystems fsck plymouth)

3. Add 'splash' to your kernel command line (GRUB in your case):
   Edit /etc/default/grub and change:
      GRUB_CMDLINE_LINUX_DEFAULT="... splash"
   Then regenerate GRUB config:
      sudo grub-mkconfig -o /boot/grub/grub.cfg

4. Rebuild all initramfs images:
      sudo mkinitcpio -P

5. (First time only) You can force the theme right now with:
      sudo plymouth-set-default-theme matugen --rebuild-initrd

6. Reboot and enjoy a boot splash that matches your current matugen theme.

After this, every wallpaper change via waypaper will automatically update
the Plymouth theme for the *next* boot (the TTY palette updates live).

If you ever want to temporarily disable the splash:
   - Remove 'splash' from GRUB_CMDLINE_LINUX_DEFAULT and regenerate GRUB.

================================================================================
INSTRUCTIONS

    shift
fi

if ! command -v plymouth >/dev/null 2>&1; then
    echo "Plymouth is not installed. Run this first:"
    echo "    sudo pacman -S plymouth"
    echo "Then follow the instructions printed by:"
    echo "    $0 --setup"
    exit 0
fi

if [ ! -f "$ENABLE_FILE" ]; then
    echo "Plymouth auto-sync is off. Enable with: touch $ENABLE_FILE" >&2
    exit 0
fi

if [ "$EUID" -ne 0 ]; then
    maybe_elevate "$@"
fi

# --- Now running as root (or with NOPASSWD) ---

# --- Resolve source colors from matugen ---
JSON_CACHE="$HOME/.cache/matugen/current.json"

if [ ! -f "$JSON_CACHE" ]; then
    echo "No matugen cache found. Set a wallpaper at least once first." >&2
    exit 1
fi

# Extract useful colors (with sane dark fallbacks)
get_hex() {
    local key="$1"
    local fallback="$2"
    jq -r --arg k "$key" --arg fb "$fallback" '
        .colors.default[$k].hex // $fb
    ' "$JSON_CACHE" 2>/dev/null || echo "$fallback"
}

SURFACE=$(get_hex "surface" "#1f1f1f")
ON_SURFACE=$(get_hex "on_surface" "#e2e2e2")
PRIMARY=$(get_hex "primary" "#98ccf9")
SURFACE_CONTAINER=$(get_hex "surface_container" "#252525")
ERROR=$(get_hex "error" "#f28b82")

# Pre-compute 0-1 RGB floats for the script (more reliable than hex parsing at runtime)
rgb_from_hex() {
    local h="${1#\#}"
    printf "%.4f %.4f %.4f" \
        $((0x${h:0:2})) $((0x${h:2:2})) $((0x${h:4:2})) | \
        awk '{printf "%.4f %.4f %.4f", $1/255, $2/255, $3/255}'
}

read -r SURFACE_R SURFACE_G SURFACE_B <<< "$(rgb_from_hex "$SURFACE")"
read -r FG_R FG_G FG_B         <<< "$(rgb_from_hex "$ON_SURFACE")"
read -r ACCENT_R ACCENT_G ACCENT_B <<< "$(rgb_from_hex "$PRIMARY")"

THEME_NAME="matugen"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
SOURCE_TEMPLATE_DIR="$HOME/.config/plymouth/matugen"

echo ":: Building Plymouth theme '$THEME_NAME' with matugen colors"
echo "   Background: $SURFACE"
echo "   Text:       $ON_SURFACE"
echo "   Accent:     $PRIMARY"

mkdir -p "$THEME_DIR"

# --- Install / update the theme files ---
# We keep a small source template tree in ~/.config/plymouth/matugen/
# The generator bakes the colors in.

if [ ! -d "$SOURCE_TEMPLATE_DIR" ]; then
    echo "ERROR: Source template directory missing: $SOURCE_TEMPLATE_DIR" >&2
    echo "The theme assets should have been created alongside this script."
    exit 1
fi

# Copy everything first
cp -a "$SOURCE_TEMPLATE_DIR"/. "$THEME_DIR"/

# Now perform color substitution in the script file(s)
shopt -s nullglob 2>/dev/null || true
for f in "$THEME_DIR"/*.script "$THEME_DIR"/*.plymouth; do
    [ -f "$f" ] || continue

    # Hex forms
    sed -i "s|{{background}}|$SURFACE|g" "$f"
    sed -i "s|{{foreground}}|$ON_SURFACE|g" "$f"
    sed -i "s|{{accent}}|$PRIMARY|g" "$f"
    sed -i "s|{{surface_container}}|$SURFACE_CONTAINER|g" "$f"
    sed -i "s|{{error}}|$ERROR|g" "$f"

    # Pre-computed 0-1 float forms (best for script themes)
    sed -i "s|{{bg_r}}|$SURFACE_R|g; s|{{bg_g}}|$SURFACE_G|g; s|{{bg_b}}|$SURFACE_B|g" "$f"
    sed -i "s|{{fg_r}}|$FG_R|g; s|{{fg_g}}|$FG_G|g; s|{{fg_b}}|$FG_B|g" "$f"
    sed -i "s|{{accent_r}}|$ACCENT_R|g; s|{{accent_g}}|$ACCENT_G|g; s|{{accent_b}}|$ACCENT_B|g" "$f"
done
shopt -u nullglob 2>/dev/null || true

# Make sure the .plymouth file points at the script correctly
if [ -f "$THEME_DIR/${THEME_NAME}.plymouth" ]; then
    sed -i "s|^ScriptFile=.*|ScriptFile=${THEME_DIR}/${THEME_NAME}.script|" "$THEME_DIR/${THEME_NAME}.plymouth" || true
fi

chmod -R 644 "$THEME_DIR"/* 2>/dev/null || true

# --- Activate the theme and rebuild initrd ---
echo ":: Setting default Plymouth theme to '$THEME_NAME' and rebuilding initramfs..."

if plymouth-set-default-theme "$THEME_NAME" --rebuild-initrd 2>/dev/null; then
    echo ":: Plymouth theme '$THEME_NAME' installed and initrd rebuilt."
    echo ":: Reboot to see the new boot splash."
else
    echo "WARNING: plymouth-set-default-theme failed or is not available."
    echo "You may need to run manually after fixing Plymouth setup:"
    echo "    sudo plymouth-set-default-theme $THEME_NAME --rebuild-initrd"
fi

exit 0
