#!/usr/bin/env bash
# font-chooser.sh
#
# Independent typography picker — changes ONLY fonts.
# Does NOT touch matugen, colors, palette, starship, waybar themes, etc.
#
# This is the parallel tool to palette.sh for the "just fonts" axis.
#
# Usage:
#   font-chooser.sh
#
# After changes it calls ~/.config/settings/apply-fonts.sh automatically.

CLASS="dotfiles-floating"
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

if [[ -z "${FONTCHOOSER_INSIDE:-}" ]]; then
    export FONTCHOOSER_INSIDE=1
    exec "${CLEAN_ENV[@]}" kitty \
        --class "$CLASS" \
        --title "Choose Fonts" \
        --override initial_window_width=72c \
        --override initial_window_height=22c \
        -e "$0" "$@"
fi

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

printf '\e]2;Choose Fonts\a' 2>/dev/null || true

FONTS_SH="$HOME/.config/settings/fonts.sh"
APPLY_SCRIPT="$HOME/.config/settings/apply-fonts.sh"

if [[ ! -f "$FONTS_SH" ]]; then
    echo "ERROR: Centralized font config not found at $FONTS_SH"
    echo "Create it first (see FONTS.md in the same directory)."
    read -r
    exit 1
fi

# Load current values (we only read, we will rewrite the three main exports)
# shellcheck source=/home/kirk/.config/settings/fonts.sh
source "$FONTS_SH"

print_header "Typography (independent from colors)"

echo "Current fonts:"
echo "  TEXT   (terminals, body) : $FONT_TEXT"
echo "  UI     (menus, waybar)   : $FONT_UI"
echo "  HEADER (big titles)      : $FONT_HEADER"
echo

# A reasonable curated list of good Nerd Fonts that are commonly installed.
# User can always edit the file manually for more exotic choices.
COMMON_FONTS=(
    "ShureTechMono Nerd Font"
    "Agave Nerd Font Propo"
    "HeavyData Nerd Font"
    "JetBrainsMono Nerd Font"
    "Iosevka Nerd Font Propo"
    "Cascadia Code Nerd Font"
    "FiraCode Nerd Font"
    "Hack Nerd Font"
    "MesloLGS Nerd Font"
    "Monaspace Neon Nerd Font"
    "VictorMono Nerd Font"
    "ComicShannsMono Nerd Font"
    "BigBlueTerm437 Nerd Font"
    "DepartureMono Nerd Font"
)

choose_font_for_role() {
    local role="$1"
    local current="$2"
    local prompt="Choose $role font (current: $current)"

    # Put the current one first in the list for easy re-selection
    local list=("$current")
    for f in "${COMMON_FONTS[@]}"; do
        [[ "$f" != "$current" ]] && list+=("$f")
    done

    # Add an "Other (type manually)" escape hatch
    list+=("Other (type exact font name)...")

    local chosen
    chosen=$(printf '%s\n' "${list[@]}" | gum choose --header "$prompt" --selected "$current" 2>/dev/null || echo "$current")

    if [[ "$chosen" == "Other (type exact font name)..." ]]; then
        chosen=$(gum input --placeholder "Exact font family name (e.g. 'Iosevka Nerd Font Propo')" --value "$current")
    fi

    echo "$chosen"
}

echo "Pick new fonts (or keep current by selecting the first item)."
echo

NEW_TEXT=$(choose_font_for_role "TEXT"   "$FONT_TEXT")
NEW_UI=$(choose_font_for_role   "UI"     "$FONT_UI")
NEW_HEADER=$(choose_font_for_role "HEADER" "$FONT_HEADER")

echo
echo "You chose:"
echo "  TEXT   → $NEW_TEXT"
echo "  UI     → $NEW_UI"
echo "  HEADER → $NEW_HEADER"
echo

if ! gum confirm "Apply these fonts now (will run apply-fonts.sh)?"; then
    echo "Cancelled. No changes made."
    exit 0
fi

# Rewrite only the three key lines in fonts.sh (safe, keeps comments, sizes, examples etc.)
sed -i "s|^export FONT_TEXT=.*|export FONT_TEXT=\"$NEW_TEXT\"|" "$FONTS_SH"
sed -i "s|^export FONT_UI=.*|export FONT_UI=\"$NEW_UI\"|" "$FONTS_SH"
sed -i "s|^export FONT_HEADER=.*|export FONT_HEADER=\"$NEW_HEADER\"|" "$FONTS_SH"

# Also update the _FULL and _FAMILY convenience vars that are derived from the above
# (they are usually right after in the file)
sed -i "s|^export FONT_TEXT_FULL=.*|export FONT_TEXT_FULL=\"\$FONT_TEXT \${FONT_SIZE_TEXT:-12}\"|" "$FONTS_SH"
sed -i "s|^export FONT_UI_FULL=.*|export FONT_UI_FULL=\"\$FONT_UI \${FONT_SIZE_UI:-12.5}\"|" "$FONTS_SH"
sed -i "s|^export FONT_HEADER_FULL=.*|export FONT_HEADER_FULL=\"\$FONT_HEADER \${FONT_SIZE_HEADER:-Regular}\"|" "$FONTS_SH"

sed -i "s|^export FONT_TEXT_FAMILY=.*|export FONT_TEXT_FAMILY=\"\$FONT_TEXT\"|" "$FONTS_SH"
sed -i "s|^export FONT_UI_FAMILY=.*|export FONT_UI_FAMILY=\"\$FONT_UI\"|" "$FONTS_SH"
sed -i "s|^export FONT_HEADER_FAMILY=.*|export FONT_HEADER_FAMILY=\"\$FONT_HEADER\"|" "$FONTS_SH"

echo
echo "Updated $FONTS_SH with the new choices."
echo "Now running the applicator..."

"$APPLY_SCRIPT"

echo
gum style --bold --foreground 2 "✓ Fonts applied. Some apps (SDDM, Hyprlock, GTK) may need logout or wallpaper change to fully refresh."
echo
read -r -p "Press Enter to close..."
