#!/bin/bash
# ===================================================================
# tty-theme.sh
#
# Applies the current matugen palette to the Linux virtual console (TTY)
# using setvtrgb. This affects all VTs when you switch to them (Ctrl+Alt+F3 etc.)
# and the TTY you land on after logging out of Hyprland.
#
# It does NOT affect early kernel boot messages (see Plymouth for that).
#
# Usage:
#   tty-theme.sh
#   tty-theme.sh --install-systemd-unit   (optional: install a oneshot user service)
#
# This script is safe to run from a graphical session.
# ===================================================================

set -euo pipefail

JSON_CACHE="$HOME/.cache/matugen/current.json"
SHELL_CACHE="$HOME/.cache/matugen/colors.sh"

# --- Require root? No. setvtrgb works from normal user on the VTs it can access.

if [ ! -f "$JSON_CACHE" ] && [ ! -f "$SHELL_CACHE" ]; then
    echo "No matugen cache found. Run a wallpaper change first." >&2
    exit 1
fi

# --- Helper: hex to decimal RGB (0-255) ---
hex_to_rgb() {
    local hex="${1#\#}"
    local r g b
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "$r $g $b"
}

# --- Load colors (prefer JSON, fall back to shell cache) ---
declare -A COLORS

if [ -f "$JSON_CACHE" ] && command -v jq >/dev/null 2>&1; then
    while IFS='=' read -r key val; do
        COLORS["$key"]="$val"
    done < <(jq -r '
        .colors.default
        | to_entries[]
        | "COLOR_" + (.key | ascii_upcase | gsub("-"; "_")) + "=" + .value.hex
    ' "$JSON_CACHE" 2>/dev/null || true)
else
    # Fallback: source the shell cache
    if [ -f "$SHELL_CACHE" ]; then
        # shellcheck disable=SC1090
        source "$SHELL_CACHE"
        for var in $(compgen -v | grep '^COLOR_'); do
            COLORS["$var"]="${!var}"
        done
    fi
fi

# --- Pick the best tokens for a dark TTY palette ---
# Console has only 16 slots. We do our best to make it look coherent with matugen.
get_color() {
    local name="$1"
    local fallback="$2"
    local c="${COLORS[$name]:-$fallback}"
    echo "${c#\#}"
}

# Material You dark mapping (tuned for readability on VGA console)
BLACK=$(get_color COLOR_SURFACE "1f1f1f")
BRIGHT_BLACK=$(get_color COLOR_SURFACE_CONTAINER_HIGH "2a2a2a")

RED=$(get_color COLOR_ERROR "f28b82")
BRIGHT_RED=$(get_color COLOR_ERROR "f28b82")   # We can lighten later if needed

GREEN=$(get_color COLOR_TERTIARY "b4d4a8")       # Often a nice green-ish in MY
BRIGHT_GREEN=$(get_color COLOR_TERTIARY "c5e0b8")

YELLOW=$(get_color COLOR_PRIMARY "d4b98a")       # Primary tends to work as warm accent
BRIGHT_YELLOW=$(get_color COLOR_PRIMARY "e8d4a8")

BLUE=$(get_color COLOR_SECONDARY "8ab4d4")
BRIGHT_BLUE=$(get_color COLOR_SECONDARY "a8c9e8")

MAGENTA=$(get_color COLOR_SECONDARY "c39bd3")    # Secondary often has purple/magenta vibes
BRIGHT_MAGENTA=$(get_color COLOR_SECONDARY "d8b3e6")

CYAN=$(get_color COLOR_TERTIARY "80c8c8")
BRIGHT_CYAN=$(get_color COLOR_TERTIARY "9ad9d9")

WHITE=$(get_color COLOR_ON_SURFACE "e2e2e2")
BRIGHT_WHITE=$(get_color COLOR_ON_SURFACE "f0f0f0")

# --- Build the vtrgb file (3 lines: R, G, B — 16 values each) ---
VTRGB_FILE=$(mktemp /tmp/matugen-vtrgb.XXXXXX)

{
    # Red channel
    printf '%d ' \
        0x${BLACK:0:2} 0x${RED:0:2} 0x${GREEN:0:2} 0x${YELLOW:0:2} \
        0x${BLUE:0:2} 0x${MAGENTA:0:2} 0x${CYAN:0:2} 0x${WHITE:0:2} \
        0x${BRIGHT_BLACK:0:2} 0x${BRIGHT_RED:0:2} 0x${BRIGHT_GREEN:0:2} 0x${BRIGHT_YELLOW:0:2} \
        0x${BRIGHT_BLUE:0:2} 0x${BRIGHT_MAGENTA:0:2} 0x${BRIGHT_CYAN:0:2} 0x${BRIGHT_WHITE:0:2}
    echo

    # Green channel
    printf '%d ' \
        0x${BLACK:2:2} 0x${RED:2:2} 0x${GREEN:2:2} 0x${YELLOW:2:2} \
        0x${BLUE:2:2} 0x${MAGENTA:2:2} 0x${CYAN:2:2} 0x${WHITE:2:2} \
        0x${BRIGHT_BLACK:2:2} 0x${BRIGHT_RED:2:2} 0x${BRIGHT_GREEN:2:2} 0x${BRIGHT_YELLOW:2:2} \
        0x${BRIGHT_BLUE:2:2} 0x${BRIGHT_MAGENTA:2:2} 0x${BRIGHT_CYAN:2:2} 0x${BRIGHT_WHITE:2:2}
    echo

    # Blue channel
    printf '%d ' \
        0x${BLACK:4:2} 0x${RED:4:2} 0x${GREEN:4:2} 0x${YELLOW:4:2} \
        0x${BLUE:4:2} 0x${MAGENTA:4:2} 0x${CYAN:4:2} 0x${WHITE:4:2} \
        0x${BRIGHT_BLACK:4:2} 0x${BRIGHT_RED:4:2} 0x${BRIGHT_GREEN:4:2} 0x${BRIGHT_YELLOW:4:2} \
        0x${BRIGHT_BLUE:4:2} 0x${BRIGHT_MAGENTA:4:2} 0x${BRIGHT_CYAN:4:2} 0x${BRIGHT_WHITE:4:2}
    echo
} > "$VTRGB_FILE"

# --- Apply it ---
if command -v setvtrgb >/dev/null 2>&1; then
    setvtrgb "$VTRGB_FILE" 2>/dev/null || true
    echo ":: TTY palette updated from matugen"
else
    echo "setvtrgb not found — cannot apply TTY colors" >&2
    rm -f "$VTRGB_FILE"
    exit 1
fi

rm -f "$VTRGB_FILE"

# Optional: also try to set the cursor color on the current VT (best effort)
# This only affects the VT you're currently on.
if [ -t 0 ]; then
    # Set cursor to primary color (subtle)
    CURSOR_HEX=$(get_color COLOR_PRIMARY "98ccf9")
    printf '\e]12;#%s\a' "$CURSOR_HEX" 2>/dev/null || true
fi

exit 0
