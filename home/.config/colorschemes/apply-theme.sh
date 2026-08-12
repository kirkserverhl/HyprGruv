#!/usr/bin/env bash
# Super+W theme apply — standard static themes only (no wallpaper matugen).
#
# Flow (from rofi-launcher): theme chosen → source/primary accent → this script.
# Applies fixed theme palettes + chosen source to: kitty, waybar, hypr, starship,
# rofi, nvim, mpv, GTK/icons/cursor, VSCodium, yazi, obsidian.
#
# Env:
#   THEME_SWITCHER_APPLY=1  (always set here — use theme slot palette)

export THEME_SWITCHER_APPLY=1

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

THEME="$1"
WALLPAPER_OVERRIDE="${2:-}"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
WALLPAPER_STATE="$HOME/.config/colorschemes/.wallpaper-state"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR="$SCRIPT_DIR/generate-preset-colors.py"
SCRIPTS="$HOME/.config/hyprgruv/scripts"
CACHE_DIR="$HOME/.cache/matugen"

# shellcheck source=wallpaper-dir.sh
source "$SCRIPT_DIR/wallpaper-dir.sh"

if [[ -z "$THEME" ]]; then
    echo -e "${YELLOW}Usage: $0 <theme-name> [wallpaper-path]${NC}"
    exit 1
fi

if [[ ! -d "$THEME_DIR" ]]; then
    echo -e "${YELLOW}Theme '$THEME' does not exist at $THEME_DIR${NC}"
    notify-send "Theme Error" "Theme '$THEME' not found" -u critical
    exit 1
fi

echo "$THEME" >"$HOME/.config/colorschemes/.current-theme"
# Drop saved active config so Super+W always uses the theme slot + source accent
rm -f "$HOME/.config/colorschemes/.active-config" 2>/dev/null || true
mkdir -p "$CACHE_DIR"
echo "preset:$THEME" >"$CACHE_DIR/yazi-icon-mode"
echo "saved" >"$CACHE_DIR/color-mode"
touch "$HOME/.config/colorschemes/.use-preset-colors"

echo -e "${GREEN}Applying standard theme: $THEME${NC}"

# --- wallpaper display only (no palette extract) ---
echo -e "${CYAN}-> Wallpaper (display only)...${NC}"
WALLPAPER=""
touch "$WALLPAPER_STATE"
if [[ -n "$WALLPAPER_OVERRIDE" && -f "$WALLPAPER_OVERRIDE" ]]; then
    WALLPAPER="$WALLPAPER_OVERRIDE"
    sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
    echo "$THEME:$WALLPAPER" >>"$WALLPAPER_STATE"
else
    SAVED=$(grep "^$THEME:" "$WALLPAPER_STATE" 2>/dev/null | cut -d':' -f2- || true)
    if [[ -n "$SAVED" && -f "$SAVED" ]]; then
        WALLPAPER="$SAVED"
    else
        WDIR="$(resolve_wallpaper_dir "$THEME" 2>/dev/null || true)"
        if [[ -n "$WDIR" && -d "$WDIR" ]]; then
            WALLPAPER=$(find "$WDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort | head -n1)
            if [[ -n "$WALLPAPER" ]]; then
                sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
                echo "$THEME:$WALLPAPER" >>"$WALLPAPER_STATE"
            fi
        fi
    fi
fi
if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    mon="all"
    if [[ -f "$HOME/.config/colorschemes/.wallpaper-monitor" ]]; then
        mon=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.wallpaper-monitor")
        [[ -z "$mon" ]] && mon="all"
    fi
    # Display + persist last_wallpaper/default_wp/waypaper so login restore matches.
    AWWW_PERSIST=1 bash "$SCRIPT_DIR/awww-wallpaper.sh" "$WALLPAPER" "$mon" >/dev/null 2>&1 || true
fi

# --- GTK / Qt / KDE / icons / cursor (standard per theme) ---
echo -e "${CYAN}-> Desktop assets (GTK, icons, cursor)...${NC}"
if [[ -x "$SCRIPTS/apply-desktop-assets.sh" ]]; then
    "$SCRIPTS/apply-desktop-assets.sh" "$THEME" 2>/dev/null || true
fi

# --- static palette + source accent → kitty, waybar, hypr, starship, rofi, nvim, mpv ---
# generate-preset-colors reads colorschemes/<theme>/user-accent when present
echo -e "${CYAN}-> Static palette + source color...${NC}"
if [[ ! -f "$GENERATOR" ]]; then
    echo -e "${YELLOW}   Missing $GENERATOR${NC}"
    notify-send "Theme Error" "generate-preset-colors.py missing" -u critical
    exit 1
fi
if ! python3 "$GENERATOR" "$THEME"; then
    echo -e "${YELLOW}   Palette generate failed for $THEME${NC}"
    notify-send "Theme Error" "Palette generate failed: $THEME" -u critical
    exit 1
fi

# User-palette mirror for tools that read matugen user-palette.json
if [[ -f "$THEME_DIR/palette.json" ]]; then
    mkdir -p "$HOME/.config/matugen"
    python3 - "$THEME_DIR/palette.json" "$HOME/.config/matugen/user-palette.json" "${WALLPAPER:-}" <<'PY' 2>/dev/null || true
import json, sys
from datetime import datetime, timezone
from pathlib import Path
src, dst, wp = sys.argv[1:4]
data = json.loads(Path(src).read_text(encoding="utf-8"))
base16 = {k.lower(): v for k, v in (data.get("base16") or {}).items()
          if isinstance(v, str) and v.startswith("#")}
Path(dst).write_text(json.dumps({
    "version": 1,
    "wallpaper": wp,
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "source": "preset-static",
    "base16": base16,
}, indent=2) + "\n", encoding="utf-8")
PY
    cp -f "$THEME_DIR/palette.json" "$CACHE_DIR/current-palette.json" 2>/dev/null || true
fi

jq -n \
    --arg wp "${WALLPAPER:-}" \
    --arg theme "$THEME" \
    '{
        wallpaper: $wp,
        method: "preset-static",
        color_mode: "saved",
        mode: "dark",
        type: "static-palette",
        theme: $theme
    }' >"$CACHE_DIR/pending-run.json" 2>/dev/null || true

# --- VSCodium standard theme name from slot ---
if [[ -f "$THEME_DIR/vscodium-theme" ]]; then
    VSCODIUM_THEME=$(tr -d '\n' <"$THEME_DIR/vscodium-theme")
    VSCODIUM_SETTINGS="$HOME/.config/VSCodium/User/settings.json"
    echo -e "${CYAN}-> VSCodium: $VSCODIUM_THEME${NC}"
    if [[ -f "$VSCODIUM_SETTINGS" ]] && command -v jq >/dev/null 2>&1; then
        tmp=$(mktemp)
        jq --arg theme "$VSCODIUM_THEME" '.["workbench.colorTheme"] = $theme' \
            "$VSCODIUM_SETTINGS" >"$tmp" && mv "$tmp" "$VSCODIUM_SETTINGS"
    fi
fi

# --- Yazi / Obsidian standard flavors ---
if [[ -x "$SCRIPTS/reload-yazi-theme.sh" ]]; then
    echo -e "${CYAN}-> Yazi flavor...${NC}"
    "$SCRIPTS/reload-yazi-theme.sh" --switch "$THEME" 2>/dev/null || true
fi
if [[ -x "$SCRIPTS/obsidian-theme.sh" ]]; then
    echo -e "${CYAN}-> Obsidian theme...${NC}"
    "$SCRIPTS/obsidian-theme.sh" "$THEME" 2>/dev/null || true
fi

# --- hot-reload visible surfaces (no matugen image, no SDDM in foreground) ---
echo -e "${CYAN}-> Reloading kitty, waybar, hypr, starship...${NC}"
for hook in hyprland waybar starship terminal swaync; do
    [[ -x "$SCRIPTS/matugen-posthook-${hook}.sh" ]] && \
        "$SCRIPTS/matugen-posthook-${hook}.sh" 2>/dev/null || true
done
[[ -x "$SCRIPTS/reload-nvim-theme.sh" ]] && \
    "$SCRIPTS/reload-nvim-theme.sh" 2>/dev/null || true

# gum/CLI color cache (fast)
if [[ -f "$SCRIPTS/colors.sh" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPTS/colors.sh" --gum 2>/dev/null || true
    if declare -F write_matugen_shell_color_cache >/dev/null 2>&1; then
        write_matugen_shell_color_cache 2>/dev/null || true
    fi
fi

# SDDM greeter wallpaper + colors in background (never block Super+W).
# Pass the wallpaper explicitly — waypaper config may be stale/broken.
if [[ -x "$SCRIPTS/update-sddm-wallpaper.sh" ]]; then
    if [[ -n "${WALLPAPER:-}" && -f "$WALLPAPER" ]]; then
        (bash "$SCRIPTS/update-sddm-wallpaper.sh" "$WALLPAPER" >/dev/null 2>&1 || true) &
    else
        (bash "$SCRIPTS/update-sddm-wallpaper.sh" >/dev/null 2>&1 || true) &
    fi
fi

hyprctl eval 'reapply_hyprbars()' 2>/dev/null || true

ACCENT=""
[[ -f "$THEME_DIR/user-accent" ]] && ACCENT=$(tr -d '[:space:]' <"$THEME_DIR/user-accent")
[[ -z "$ACCENT" && -f "$THEME_DIR/source-color" ]] && ACCENT=$(tr -d '[:space:]' <"$THEME_DIR/source-color")
# Fallback: primary from written matugen hypr conf
if [[ -z "$ACCENT" && -f "$HOME/.config/hypr/colors/custom/matugen.conf" ]]; then
    ACCENT=$(sed -n 's/^\$base0D = rgba(\([0-9a-fA-F]\{6\}\).*/#\1/p' \
        "$HOME/.config/hypr/colors/custom/matugen.conf" | head -1)
fi

# Force borders immediately (Lua apply_borders on reload can race)
if [[ -n "$ACCENT" ]]; then
    hex="${ACCENT#\#}"
    hex="${hex,,}"
    if [[ "$hex" =~ ^[0-9a-f]{6}$ ]]; then
        hyprctl keyword general:col.active_border "rgba(${hex}ff)" >/dev/null 2>&1 || true
    fi
fi
# Inactive = theme secondary (base0E) — readable, not grey
inactive=$(sed -n 's/^\$base0E = rgba(\([0-9a-fA-F]\{6\}\).*/\1/p' \
    "$HOME/.config/hypr/colors/custom/matugen.conf" 2>/dev/null | head -1)
if [[ -n "$inactive" ]]; then
    hyprctl keyword general:col.inactive_border "rgba(${inactive}cc)" >/dev/null 2>&1 || true
fi


echo -e "${GREEN}Done: $THEME${ACCENT:+ (source $ACCENT)}${NC}"
notify-send "Theme Applied" "Standard theme: $THEME${ACCENT:+ · source $ACCENT}" -t 3500
