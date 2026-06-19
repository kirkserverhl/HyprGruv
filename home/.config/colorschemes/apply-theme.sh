#!/bin/bash
# Explicit Super+W theme pick — use the theme slot's palette, not a saved active config.
export THEME_SWITCHER_APPLY=1

# Color codes
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

THEME="$1"
WALLPAPER_OVERRIDE="$2"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
WALLPAPER_STATE="$HOME/.config/colorschemes/.wallpaper-state"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=wallpaper-dir.sh
source "$SCRIPT_DIR/wallpaper-dir.sh"
# shellcheck source=theme-assets.sh
source "$SCRIPT_DIR/theme-assets.sh"

if [ -z "$THEME" ]; then
    echo -e "${YELLOW}Usage: $0 <theme-name>${NC}"
    exit 1
fi

if [ ! -d "$THEME_DIR" ]; then
    echo -e "${YELLOW}Theme '$THEME' does not exist at $THEME_DIR${NC}"
    notify-send "Theme Error" "Theme '$THEME' not found" -u critical
    exit 1
fi

CURRENT_THEME_FILE="$HOME/.config/colorschemes/.current-theme"
echo "$THEME" >"$CURRENT_THEME_FILE"
mkdir -p "$HOME/.cache/matugen"
echo "preset:$THEME" >"$HOME/.cache/matugen/yazi-icon-mode"


echo -e "${GREEN}Applying theme: $THEME${NC}\n"
notify-send "Theme Switching" "Applying theme: $THEME" -t 3000

# Resolve wallpaper first (display only — colors come from static theme seed)
echo -e "${CYAN}-> Resolving wallpaper...${NC}"
WALLPAPER_DIR="$(resolve_wallpaper_dir "$THEME")"
touch "$WALLPAPER_STATE"
SAVED_WALLPAPER=$(grep "^$THEME:" "$WALLPAPER_STATE" | cut -d':' -f2-)

if [ -n "$WALLPAPER_OVERRIDE" ] && [ -f "$WALLPAPER_OVERRIDE" ]; then
    WALLPAPER="$WALLPAPER_OVERRIDE"
    sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
    echo "$THEME:$WALLPAPER" >>"$WALLPAPER_STATE"
    echo -e "${CYAN}   Using selected wallpaper${NC}"
elif [ -n "$SAVED_WALLPAPER" ] && [ -f "$SAVED_WALLPAPER" ]; then
    WALLPAPER="$SAVED_WALLPAPER"
    echo -e "${CYAN}   Using saved wallpaper${NC}"
elif [ -n "$WALLPAPER_DIR" ] && [ -d "$WALLPAPER_DIR" ]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort | head -n1)
    if [ -n "$WALLPAPER" ]; then
        sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
        echo "$THEME:$WALLPAPER" >>"$WALLPAPER_STATE"
        echo -e "${CYAN}   Using first wallpaper (default)${NC}"
    else
        echo -e "${YELLOW}   No wallpapers found in $WALLPAPER_DIR${NC}"
    fi
else
    echo -e "${YELLOW}   Wallpaper directory not found${NC}"
fi
echo ""

# GTK window theme from ~/.themes
if [ -f "$THEME_DIR/gtk-theme" ]; then
    GTK_THEME_NAME=$(cat "$THEME_DIR/gtk-theme")
    echo -e "${CYAN}-> Setting GTK theme to '$GTK_THEME_NAME'...${NC}"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME" >/dev/null 2>&1
else
    echo -e "${YELLOW}-> GTK theme file not found. Skipping.${NC}"
fi
echo ""

GTK4_SRC="$THEME_DIR/gtk-4.0"
GTK4_DST="$HOME/.config/gtk-4.0"

if [[ -d "$GTK4_SRC" ]]; then
    echo -e "${CYAN}-> Linking GTK4 theme files...${NC}"
    mkdir -p "$GTK4_DST"
    ln -sf "$GTK4_SRC/gtk.css" "$GTK4_DST/gtk.css"
    ln -sf "$GTK4_SRC/gtk-dark.css" "$GTK4_DST/gtk-dark.css"
    ln -sfn "$GTK4_SRC/assets" "$GTK4_DST/assets"
else
    echo -e "${YELLOW}-> No GTK4 theme files found in $GTK4_SRC. Skipping.${NC}"
fi
echo ""

# Colors from saved palette.json or active configuration (static — no pywal re-extract).
echo -e "${CYAN}-> Applying static palette for $THEME...${NC}"
if bash "$SCRIPT_DIR/apply-preset-assets.sh" "$THEME" "${WALLPAPER:-}"; then
    echo -e "${CYAN}   Saved palette → starship, waybar, hyprbars, hypr, rofi${NC}"
else
    echo -e "${YELLOW}   Palette apply failed — some app colors may be stale${NC}"
fi
echo ""

# Wallpaper display (colors already matched above)
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    echo -e "${CYAN}-> Setting wallpaper...${NC}"
    APPLY_MONITOR="all"
    if [[ -f "$HOME/.config/colorschemes/.wallpaper-monitor" ]]; then
        APPLY_MONITOR=$(cat "$HOME/.config/colorschemes/.wallpaper-monitor")
        [[ -z "$APPLY_MONITOR" ]] && APPLY_MONITOR="all"
    fi
    bash "$SCRIPT_DIR/awww-wallpaper.sh" "$WALLPAPER" "$APPLY_MONITOR" >/dev/null 2>&1
else
    echo -e "${YELLOW}-> Could not set wallpaper${NC}"
fi
echo ""

# VSCodium theme (not handled by matugen)
if [ -f "$THEME_DIR/vscodium-theme" ]; then
    VSCODIUM_THEME=$(cat "$THEME_DIR/vscodium-theme")
    VSCODIUM_SETTINGS="$HOME/.config/VSCodium/User/settings.json"

    echo -e "${CYAN}-> Setting VSCodium theme to '$VSCODIUM_THEME'...${NC}"

    if command -v jq >/dev/null 2>&1; then
        tmpfile=$(mktemp)
        jq --arg theme "$VSCODIUM_THEME" '.["workbench.colorTheme"] = $theme' "$VSCODIUM_SETTINGS" >"$tmpfile" && mv "$tmpfile" "$VSCODIUM_SETTINGS"
    else
        sed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"$VSCODIUM_THEME\"/" "$VSCODIUM_SETTINGS"
    fi
else
    echo -e "${YELLOW}-> VSCodium theme file not found. Skipping.${NC}"
fi
echo ""

notify-send "Theme Applied" "Successfully switched to: $THEME" -t 5000