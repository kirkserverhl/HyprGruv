#!/usr/bin/env bash
# Super+W theme apply — named theme configs first; matugen only for apps
# that have no official theme file.
#
# Flow: theme + wallpaper + source accent → official presets (starship,
# kitty, nvim, hypr, yazi, obsidian, vscodium) → leftover matugen json
# (waybar, swaync, rofi, …) → reload leftover hooks only.
# Do not let matugen paint starship/kitty/nvim first — they flash then get
# overwritten by --tailored.
#
# ── Named theme / official config (do NOT need matugen output) ──────────
# Super+W already points these at a real theme. A posthook/reload is enough.
#
#   GTK 3/4 + gtkrc-2     apply-desktop-assets   Gruvbox-Dark / Catppuccin-Dark / Nordic-darker / Everforest-Dark / Graphite-Dark-compact
#   Icons                 apply-desktop-assets   Gruvbox-Plus-Dark / Papirus / Zafiro-Nord / GreyStone / …
#   Cursors               apply-desktop-assets   Bibata-Gruvbox / Nordzy / …
#   KDE look-and-feel     apply-desktop-assets   named Plasma LNF (not Matugen.colors)
#   Kitty                 --tailored             official *.conf (catppuccin-mocha, nord, everforest-dark, …)
#   Starship              --tailored             colorschemes/<theme>/starship-rainbow.toml
#   Yazi                  reload-yazi-theme      flavor (catppuccin-mocha, nord, everforest-medium, gruvbox-dark)
#   VSCodium              slot vscodium-theme    "Catppuccin Mocha", "Nord Wave", "Everforest Dark", …
#   Obsidian              obsidian-theme.sh      community cssTheme (Catppuccin, Obsidian Nord, …)
#
# ── Slot files that exist but Super+W does not apply yet ────────────────
#   discord/current.theme.css   spicetify-theme   nvim/lua/chadrc.lua
#   (nvim today reloads matugen-theme.lua, not the slot chadrc)
#
# ── Matugen leftover only (no official theme, or must follow source) ─
#   SwayNC/Overwatch   Waybar   Hyprlock   Rofi   Wlogout
#   Firefox / pywalfox / chrome user CSS
#   bat  btop  cava  tmux  alacritty  mpv  grok  gum
#   qt5ct/qt6ct colors   Kvantum   qBittorrent   pacseek   pavucontrol
#   terminal OSC sequences
#   Hyprland colors come from --tailored (write_hypr), not the matugen template
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
BUILDER="$HOME/.config/hyprgruv/scripts/palette-build-import.py"
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

ENSURE_HYPR="${HYPR_DIR:-$HOME/.hyprgruv}/lib/scripts/ensure-hypr-config.sh"
if [[ -f "$ENSURE_HYPR" ]]; then
    bash "$ENSURE_HYPR" 2>/dev/null || true
elif [[ -f "$HOME/.hyprgruv/lib/scripts/ensure-hypr-config.sh" ]]; then
    bash "$HOME/.hyprgruv/lib/scripts/ensure-hypr-config.sh" 2>/dev/null || true
fi

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
        DEFAULT_WP_NAME=""
        [[ -f "$THEME_DIR/default-wallpaper" ]] && \
            DEFAULT_WP_NAME=$(tr -d '[:space:]' <"$THEME_DIR/default-wallpaper")
        WDIR="$(resolve_wallpaper_dir "$THEME" 2>/dev/null || true)"
        if [[ -n "$DEFAULT_WP_NAME" ]]; then
            for candidate in \
                "$HOME/Pictures/Wallpapers/$DEFAULT_WP_NAME" \
                "$THEME_DIR/wallpapers/$DEFAULT_WP_NAME" \
                "${WDIR:-}/$DEFAULT_WP_NAME"
            do
                [[ -n "$candidate" && -f "$candidate" ]] || continue
                WALLPAPER="$candidate"
                break
            done
        fi
        if [[ -z "$WALLPAPER" && -n "$WDIR" && -d "$WDIR" ]]; then
            WALLPAPER=$(find "$WDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort | head -n1)
        fi
        if [[ -n "$WALLPAPER" ]]; then
            sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
            echo "$THEME:$WALLPAPER" >>"$WALLPAPER_STATE"
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

# --- slot palette + Super+W source ---
echo -e "${CYAN}-> Static palette + source color...${NC}"
if [[ ! -f "$GENERATOR" ]]; then
    echo -e "${YELLOW}   Missing $GENERATOR${NC}"
    notify-send "Theme Error" "generate-preset-colors.py missing" -u critical
    exit 1
fi
if ! python3 "$GENERATOR" --prepare "$THEME"; then
    echo -e "${YELLOW}   Palette prepare failed for $THEME${NC}"
    notify-send "Theme Error" "Palette prepare failed: $THEME" -u critical
    exit 1
fi

# Official presets FIRST so starship/kitty/nvim never flash a matugen palette.
echo -e "${CYAN}-> Official starship / kitty / neovim / hypr...${NC}"
python3 "$GENERATOR" --tailored "$THEME" || true
if [[ -x "$SCRIPTS/matugen-posthook-starship.sh" || -f "$SCRIPTS/matugen-posthook-starship.sh" ]]; then
    bash "$SCRIPTS/matugen-posthook-starship.sh" 2>/dev/null || true
fi
if [[ -x "$SCRIPTS/reload-kitty-colors.sh" || -f "$SCRIPTS/reload-kitty-colors.sh" ]]; then
    bash "$SCRIPTS/reload-kitty-colors.sh" 2>/dev/null || true
fi
if [[ -x "$SCRIPTS/reload-nvim-theme.sh" || -f "$SCRIPTS/reload-nvim-theme.sh" ]]; then
    bash "$SCRIPTS/reload-nvim-theme.sh" 2>/dev/null || true
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

# Leftover apps only (waybar, swaync, rofi, gtk colors, …). Skips starship/kitty/nvim.
if [[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]]; then
    for f in "$HOME/.config/last_wallpaper.txt" "$HOME/.config/settings/default"; do
        if [[ -f "$f" ]]; then
            WALLPAPER=$(tr -d '\n' <"$f")
            [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]] && break
        fi
    done
fi
LEFTOVER="$SCRIPTS/matugen-leftover.sh"
if [[ -n "${WALLPAPER:-}" && -f "$WALLPAPER" && -f "$BUILDER" ]] && command -v matugen >/dev/null 2>&1; then
    echo -e "${CYAN}-> Leftover matugen (waybar, swaync, rofi, …)...${NC}"
    IMPORT_JSON="$CACHE_DIR/saved-import.json"
    if python3 "$BUILDER" build-base16 "$THEME_DIR/palette.json" "$WALLPAPER" "$IMPORT_JSON"; then
        if [[ -f "$LEFTOVER" ]]; then
            bash "$LEFTOVER" "$IMPORT_JSON" "$THEME" || true
        else
            matugen json "$IMPORT_JSON" --continue-on-error || true
        fi
    else
        echo -e "${YELLOW}   Import JSON failed — leftover templates not refreshed${NC}"
    fi
else
    echo -e "${YELLOW}   Skipping leftover matugen (need wallpaper + matugen)${NC}"
fi

# --- hot-reload leftover surfaces (do not re-touch official presets) ---
echo -e "${CYAN}-> Reloading waybar, hypr, swaync...${NC}"
export RELOAD_SKIP_PRESETS=1
if [[ -x "$SCRIPTS/reload-matugen-visible.sh" ]]; then
    "$SCRIPTS/reload-matugen-visible.sh" 2>/dev/null || true
else
    for hook in hyprland waybar terminal swaync gum; do
        [[ -x "$SCRIPTS/matugen-posthook-${hook}.sh" ]] && \
            "$SCRIPTS/matugen-posthook-${hook}.sh" 2>/dev/null || true
    done
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

# Reload Hyprland AFTER tailored starship/rainbow so hyprbars buttons
# (the three titlebar "quarters") pick up the new palette. hyprbars can
# only add_button — a reload clears the old ones first.
echo -e "${CYAN}-> Hyprland borders + hyprbars...${NC}"
if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    timeout 8 hyprctl reload >/dev/null 2>&1 || true
else
    echo -e "${YELLOW}   skip hyprctl reload — $HOME/.config/hypr/hyprland.lua missing${NC}"
fi
hyprctl eval 'apply_borders()' >/dev/null 2>&1 || true
hyprctl eval 'reapply_hyprbars()' >/dev/null 2>&1 || true
if [[ -n "$ACCENT" ]]; then
    hex="${ACCENT#\#}"
    hex="${hex,,}"
    if [[ "$hex" =~ ^[0-9a-f]{6}$ ]]; then
        hyprctl keyword general:col.active_border "rgba(${hex}ff)" >/dev/null 2>&1 || true
    fi
fi
inactive=$(sed -n 's/^\$base0E = rgba(\([0-9a-fA-F]\{6\}\).*/\1/p' \
    "$HOME/.config/hypr/colors/custom/matugen.conf" 2>/dev/null | head -1)
if [[ -n "$inactive" ]]; then
    hyprctl keyword general:col.inactive_border "rgba(${inactive}cc)" >/dev/null 2>&1 || true
fi


echo -e "${GREEN}Done: $THEME${ACCENT:+ (source $ACCENT)}${NC}"
notify-send "Theme Applied" "Standard theme: $THEME${ACCENT:+ · source $ACCENT}" -t 3500
