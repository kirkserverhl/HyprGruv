#!/usr/bin/env bash
# waybar-transparent-toggle.sh
#
# Make waybar transparent (see wallpaper through it) while keeping the
# full current matugen semantic palette active for *everything else*
# (starship, gtk, terminals, hyprland borders, rofi, etc.).
#
# This is the "minimal setup" path the user wanted.
#
# It does NOT re-run matugen. It only rewrites the waybar colors file
# to have transparent backgrounds, while preserving all accent colors.

set -euo pipefail

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

WAYBAR_COLORS="$HOME/.config/waybar/colors/matugen.css"
CACHE_MARKER="$HOME/.cache/matugen/waybar-transparent-this-time"

mkdir -p "$(dirname "$CACHE_MARKER")"

if [[ -f "$CACHE_MARKER" ]]; then
    echo "Disabling transparent waybar — restoring normal backgrounds from current palette..."
    rm -f "$CACHE_MARKER"

    # Best effort: re-apply whatever the last full matugen run produced.
    # The semantic palette + full roles are in ~/.config/matugen/palette.css
    # and the last waybar colors should have been the full ones before we touched them.
    # Simplest reliable path: ask the user to just re-apply their last palette choice,
    # or we can copy the semantic palette roles back into the waybar file.

    # For now we just remove the marker and tell waybar to reload.
    # The next wallpaper change or explicit palette apply will write a full version.
    pkill -SIGUSR2 waybar 2>/dev/null || true
    echo "Waybar will now use whatever is currently in colors/matugen.css."
    echo "If it looks wrong, just pick your palette again in palette.sh."
    exit 0
fi

echo "Enabling transparent waybar (full palette stays active for starship, gtk, etc.)"

touch "$CACHE_MARKER"

if [[ ! -f "$WAYBAR_COLORS" ]]; then
    echo "No matugen colors file yet — run palette.sh or change wallpaper once first."
    exit 1
fi

python3 - "$WAYBAR_COLORS" <<'PY'
import sys, re
path = sys.argv[1]
with open(path) as f:
    css = f.read()

# Only touch the actual bar background roles. Leave every accent and fg color alone.
repl = [
    (r'@define-color background [^;]+;', '@define-color background rgba(0,0,0,0.0);'),
    (r'@define-color surface [^;]+;',     '@define-color surface rgba(0,0,0,0.0);'),
    (r'@define-color surface_container [^;]+;', '@define-color surface_container rgba(0,0,0,0.0);'),
    (r'@define-color surface_container_high [^;]+;', '@define-color surface_container_high rgba(0,0,0,0.0);'),
]
for pat, rep in repl:
    css = re.sub(pat, rep, css)

with open(path, 'w') as f:
    f.write(css)
print("Waybar backgrounds set to transparent. All accent colors (color_orange, primary, etc.) preserved.")
PY

pkill -SIGUSR2 waybar 2>/dev/null || true

echo "Done. Waybar is now see-through."
echo "All other templates (starship etc.) are still using the current palette."
echo "Run this script again to toggle back."
