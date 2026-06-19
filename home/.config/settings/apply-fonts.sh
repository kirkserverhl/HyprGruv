#!/bin/bash
# =============================================================================
# apply-fonts.sh
# Push the three central fonts from ~/.config/settings/fonts.sh to all consumers.
#
# Run this after editing fonts.sh
# =============================================================================

set -euo pipefail

FONTS_SH="$HOME/.config/settings/fonts.sh"

if [[ ! -f "$FONTS_SH" ]]; then
    echo "ERROR: $FONTS_SH not found" >&2
    exit 1
fi

# shellcheck source=/home/kirk/.config/settings/fonts.sh
source "$FONTS_SH"

echo "==> Applying fonts from central config:"
echo "    TEXT   : $FONT_TEXT  (terminals, dunst, etc.)"
echo "    UI     : $FONT_UI    (menus, waybar, rofi, gtk)"
echo "    HEADER : $FONT_HEADER (sddm, hyprlock big elements, wlogout)"
echo

# Helper: safely replace a line containing a font assignment
replace_font_line() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    if [[ -f "$file" ]]; then
        sed -i "s|${pattern}.*|$replacement|" "$file"
        echo "  ✓ Updated $file"
    else
        echo "  ! Skipped (not found): $file"
    fi
}

# =============================================================================
# 1. ROFI - the best citizen (already had good centralization)
# =============================================================================
ROFI_FONT_FILE="$HOME/.config/settings/rofi-font.rasi"
if [[ -f "$ROFI_FONT_FILE" ]]; then
    cat > "$ROFI_FONT_FILE" << EOF
/* Single source of truth for Rofi font (managed by apply-fonts.sh) */
configuration {
    font: "$FONT_UI ${FONT_SIZE_LAUNCHER:-16}";
}
EOF
    echo "  ✓ Updated $ROFI_FONT_FILE → $FONT_UI ${FONT_SIZE_LAUNCHER:-16}"
fi

# Also keep the newer fonts.rasi in sync
ROFI_FONTS_FILE="$HOME/.config/settings/fonts.rasi"
cat > "$ROFI_FONTS_FILE" << EOF
/* Centralized Rofi Font - managed by apply-fonts.sh
   Source: ~/.config/settings/fonts.sh  (FONT_UI role)
*/
configuration {
    font: "$FONT_UI ${FONT_SIZE_LAUNCHER:-16}";
}
EOF
echo "  ✓ Updated $ROFI_FONTS_FILE → $FONT_UI ${FONT_SIZE_LAUNCHER:-16}"

LAUNCHER_CHROME_RASI="$HOME/.config/rofi/shared/launcher-chrome.rasi"
if [[ -f "$LAUNCHER_CHROME_RASI" ]]; then
    sed -i "s|font: \".*\";|font: \"$FONT_UI ${FONT_SIZE_LAUNCHER:-16}\";|" "$LAUNCHER_CHROME_RASI"
    echo "  ✓ Updated $LAUNCHER_CHROME_RASI → $FONT_UI ${FONT_SIZE_LAUNCHER:-16}"
fi

# =============================================================================
# 2. WAYBAR - main active styles (Agave = UI role)
#    We update the primary ones. Theme variants may still need manual love.
# =============================================================================
WAYBAR_BASES=(
    "$HOME/.config/waybar/freshstart.css"
    "$HOME/.config/waybar/style-rainbow.css"
    "$HOME/.config/waybar/themes/gruv-modern/style.css"
    "$HOME/.config/waybar/themes/gruv/style.css"
)

for css in "${WAYBAR_BASES[@]}"; do
    if [[ -f "$css" ]]; then
        # Replace common Agave/JetBrains references with our UI font (avoid duplication)
        sed -i "s|\"Agave Nerd Font\"[^,\"]*|\"$FONT_UI\"|g" "$css"
        sed -i "s|\"JetBrainsMono Nerd Font\"[^,\"]*|\"$FONT_UI\"|g" "$css"
        # Collapse accidental duplicate consecutive entries
        sed -i "s|\"$FONT_UI\", \"$FONT_UI\"|\"$FONT_UI\"|g" "$css"
        echo "  ✓ Updated waybar: $(basename "$(dirname "$css")")/$(basename "$css")"
    fi
done

# =============================================================================
# 4. TERMINALS → TEXT font
# =============================================================================
# Kitty
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if [[ -f "$KITTY_CONF" ]]; then
    sed -i "s|^font_family .*|font_family      $FONT_TEXT|" "$KITTY_CONF"
    echo "  ✓ Updated kitty.conf → $FONT_TEXT"
fi

# Ghostty
GHOSTTY_CONF="$HOME/.config/ghostty/config"
if [[ -f "$GHOSTTY_CONF" ]]; then
    sed -i "s|^font-family = .*|font-family = $FONT_TEXT|" "$GHOSTTY_CONF"
    # Also update the comment block if present
    sed -i "s|ShureTechMono Nerd Font|$FONT_TEXT|g" "$GHOSTTY_CONF"
    echo "  ✓ Updated ghostty/config → $FONT_TEXT"
fi

# =============================================================================
# 5. DUNST notifications → TEXT font (body text)
# =============================================================================
DUNST_CONF="$HOME/.config/dunst/dunstrc"
if [[ -f "$DUNST_CONF" ]]; then
    sed -i "s|^font = .*|font = $FONT_TEXT $FONT_SIZE_TEXT|" "$DUNST_CONF"
    echo "  ✓ Updated dunstrc → $FONT_TEXT"
fi

# =============================================================================
# 6. HYPRLOCK - mix of HEADER (big/important) + UI (secondary)
# =============================================================================
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock/hyprlock.conf"
if [[ -f "$HYPRLOCK_CONF" ]]; then
    # Use perl for more reliable multi-word + optional "Regular" replacement
    perl -i -pe '
        s/font_family\s*=\s*"\K[^"]*(HeavyData|heavydata)[^"]*/'"$FONT_HEADER_REGULAR"'/gi;
        s/font_family\s*=\s*"\K[^"]*(Agave|agave)[^"]*/'"$FONT_UI_PROPO_REGULAR"'/gi;
    ' "$HYPRLOCK_CONF" 2>/dev/null || true

    # Fallback broad replace if perl missed something
    sed -i "s/HeavyData Nerd Font[^\"]*/$FONT_HEADER_REGULAR/g" "$HYPRLOCK_CONF"
    sed -i "s/Agave Nerd Font Propo[^\"]*/$FONT_UI_PROPO_REGULAR/g" "$HYPRLOCK_CONF"

    echo "  ✓ Updated hyprlock.conf (HEADER + UI roles applied)"
fi

# =============================================================================
# 7. WLOGOUT (power menu - special header-like UI) → HEADER
# =============================================================================
WLOGOUT_CSS="$HOME/.config/wlogout/style.css"
if [[ -f "$WLOGOUT_CSS" ]]; then
    sed -i "s|\"HeavyData Nerd Font\"|\"$FONT_HEADER\"|g" "$WLOGOUT_CSS"
    echo "  ✓ Updated wlogout/style.css → $FONT_HEADER"
fi

# =============================================================================
# 8. GTK (app menus, file pickers, etc.) → UI
# =============================================================================
for gtkcss in "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"; do
    if [[ -f "$gtkcss" ]]; then
        sed -i "s|\"Agave Propo\"[^,]*|\"$FONT_UI\"|g" "$gtkcss"
        sed -i "s|\"Agave Nerd Font Propo\"[^,]*|\"$FONT_UI\"|g" "$gtkcss"
        echo "  ✓ Updated $(basename "$(dirname "$gtkcss")")/$(basename "$gtkcss") → $FONT_UI"
    fi
done

# =============================================================================
# 9. SDDM (sugar-candy theme) - update the patcher script itself
#    The actual theme.conf gets written at wallpaper change time.
# =============================================================================
SDDM_PATCHER="$HOME/.config/hyprgruv/scripts/update-sddm-wallpaper.sh"
if [[ -f "$SDDM_PATCHER" ]]; then
    # Change the hardcoded HeavyData line to use our central variable
    sed -i 's|Font="HeavyData Nerd Font"|Font="'"$FONT_HEADER"'"|g' "$SDDM_PATCHER"
    sed -i 's|Font="HeavyData Nerd Font Regular"|Font="'"$FONT_HEADER"'"|g' "$SDDM_PATCHER"
    echo "  ✓ Updated SDDM patcher script (will use $FONT_HEADER on next wallpaper change)"
fi

# =============================================================================
# 10. Hyprland plugins (hyprbars) - treat as UI element
# =============================================================================
for plugin_lua in "$HOME/.config/hypr/conf/plugins.lua" "$HOME/.config/hyprlua/conf/plugins.lua"; do
    if [[ -f "$plugin_lua" ]]; then
        sed -i 's|JetBrainsMono Nerd Font Propo Regular|'"$FONT_UI"'|g' "$plugin_lua"
        echo "  ✓ Updated $(basename "$(dirname "$plugin_lua")")/$(basename "$plugin_lua") → $FONT_UI"
    fi
done

# =============================================================================
# 11. WAYPAPER — GTK classic + waypaper-engine (both follow fonts.sh)
# =============================================================================
if [[ -x "$HOME/.config/settings/waypaper-rebuild-style.sh" ]]; then
    "$HOME/.config/settings/waypaper-rebuild-style.sh"
fi
if [[ -x "$HOME/.config/settings/waypaper-engine-fonts.sh" ]]; then
    "$HOME/.config/settings/waypaper-engine-fonts.sh"
fi

# =============================================================================
# 12. OBSIDIAN — document text + heading fonts
# =============================================================================
if [[ -x "$HOME/.config/settings/obsidian-fonts.sh" ]]; then
    "$HOME/.config/settings/obsidian-fonts.sh"
fi

# =============================================================================
# 13. Optional: write a small env file that other scripts can source easily
# =============================================================================
ENV_FILE="$HOME/.config/settings/fonts.env"
cat > "$ENV_FILE" << EOF
# Generated by apply-fonts.sh - do not edit directly
# Source this from other scripts if you need the font names
FONT_TEXT="$FONT_TEXT"
FONT_UI="$FONT_UI"
FONT_HEADER="$FONT_HEADER"
FONT_TEXT_FULL="$FONT_TEXT_FULL"
FONT_UI_FULL="$FONT_UI_FULL"
FONT_HEADER_FULL="$FONT_HEADER_FULL"
EOF
echo "  ✓ Wrote $ENV_FILE (for scripts that prefer env files)"

echo
echo "==> Font application complete."
echo "    Some changes (SDDM, certain waybar themes) take effect after logout or wallpaper change."
echo "    Hyprland plugins may need a Hyprland reload (Super+Shift+R or hyprctl reload)."
