#!/usr/bin/env bash
# apply-matugen-auto.sh — cached matugen apply with logging + fast visible reloads
#
# Usage: apply-matugen-auto.sh [/path/to/wallpaper.png]
# Env:   MATUGEN_FORCE=1  skip cache and regenerate all templates
#        MATUGEN_CACHE=0  same as MATUGEN_FORCE=1

set -euo pipefail

WALLPAPER="${1:-}"
SCRIPTS="$HOME/.config/hypr/scripts"
CACHE_DIR="$HOME/.cache/matugen"
MANIFEST="$CACHE_DIR/last-run.json"
LOG="$CACHE_DIR/matugen.log"
RUNS="$CACHE_DIR/runs"
EXTRACTOR="$SCRIPTS/extract-good-source-colors.sh"

KITTY_COLORS="$HOME/.config/kitty/colors.conf"
HYPR_COLORS="$HOME/.config/hypr/colors/custom/matugen.conf"
STARSHIP_MATUGEN="$HOME/.config/starship/matugen-rainbow.toml"
STARSHIP_ACTIVE="$HOME/.config/starship.toml"
WAYBAR_COLORS="$HOME/.config/waybar/colors/matugen.css"

mkdir -p "$CACHE_DIR" "$RUNS"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

if [[ -z "$WALLPAPER" ]]; then
    WP_CACHE="$HOME/.config/settings/cache/current_wallpaper"
    [[ -f "$WP_CACHE" ]] && WALLPAPER=$(cat "$WP_CACHE")
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    log "ERROR: no valid wallpaper for matugen apply"
    exit 1
fi

if ! command -v matugen >/dev/null 2>&1; then
    log "ERROR: matugen not installed"
    exit 1
fi

rm -f "$CACHE_DIR/no-matugen-this-time" 2>/dev/null || true

MATUGEN_SRC="#a78a9d"
if [[ -x "$EXTRACTOR" ]]; then
    MATUGEN_SRC=$("$EXTRACTOR" "$WALLPAPER" 1 2>/dev/null | head -1)
    [[ -z "$MATUGEN_SRC" ]] && MATUGEN_SRC="#a78a9d"
fi

WP_MTIME=$(stat -c %Y "$WALLPAPER" 2>/dev/null || echo 0)
CACHE_KEY="${WALLPAPER}|${MATUGEN_SRC}|${WP_MTIME}"

priority_files_ok() {
    [[ -s "$KITTY_COLORS" && -s "$HYPR_COLORS" && -s "$STARSHIP_MATUGEN" && -s "$WAYBAR_COLORS" ]]
}

cache_hit() {
    [[ "${MATUGEN_FORCE:-0}" == "1" || "${MATUGEN_CACHE:-1}" == "0" ]] && return 1
    [[ -f "$MANIFEST" ]] || return 1
    priority_files_ok || return 1
    local key
    key=$(jq -r '.cache_key // empty' "$MANIFEST" 2>/dev/null || true)
    [[ "$key" == "$CACHE_KEY" ]]
}

write_manifest() {
    local mode="${1:-run}"
    local primary="${2:-}"
    [[ -z "$primary" && -f "$STARSHIP_MATUGEN" ]] && \
        primary=$(grep -m1 '^color_orange' "$STARSHIP_MATUGEN" 2>/dev/null | sed -E "s/.*= *['\"]?([^'\"]+)['\"]?.*/\1/" || true)
    jq -n \
        --arg wp "$WALLPAPER" \
        --arg src "$MATUGEN_SRC" \
        --arg key "$CACHE_KEY" \
        --arg primary "${primary:-}" \
        --arg mode "$mode" \
        --argjson mtime "${WP_MTIME:-0}" \
        --arg at "$(date -Iseconds)" \
        '{
            wallpaper: $wp,
            source_hex: $src,
            cache_key: $key,
            wallpaper_mtime: $mtime,
            primary: $primary,
            mode: $mode,
            ran_at: $at
        }' > "$MANIFEST"
}

reload_visible_themes() {
    if [[ -f "$STARSHIP_MATUGEN" ]]; then
        touch "$STARSHIP_MATUGEN" 2>/dev/null || true
        if [[ -L "$STARSHIP_ACTIVE" ]]; then
            active_target=$(readlink -f "$STARSHIP_ACTIVE" 2>/dev/null || true)
            if [[ "$active_target" == "$STARSHIP_MATUGEN" || "$(basename "$active_target" 2>/dev/null)" == matugen-rainbow.toml ]]; then
                ln -sfn "$STARSHIP_MATUGEN" "$STARSHIP_ACTIVE" 2>/dev/null || true
                touch "$STARSHIP_ACTIVE" 2>/dev/null || true
            fi
        elif [[ ! -e "$STARSHIP_ACTIVE" ]]; then
            ln -sfn "$STARSHIP_MATUGEN" "$STARSHIP_ACTIVE" 2>/dev/null || true
        fi
    fi

    if [[ -f "$WAYBAR_COLORS" ]]; then
        cp -f "$WAYBAR_COLORS" "$HOME/.config/waybar/colors.css" 2>/dev/null || true
    fi

    "$SCRIPTS/reload-kitty-colors.sh" 2>/dev/null || true
    timeout 2 hyprctl reload 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
}

wait_for_priority_templates() {
    local start_ts="$1"
    local f mtime
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        if priority_files_ok; then
            local ready=1
            for f in "$KITTY_COLORS" "$HYPR_COLORS" "$STARSHIP_MATUGEN" "$WAYBAR_COLORS"; do
                mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
                if [[ "$mtime" -lt "$start_ts" ]]; then
                    ready=0
                    break
                fi
            done
            [[ "$ready" -eq 1 ]] && return 0
        fi
        sleep 0.1
    done
    return 0
}

if cache_hit; then
    log "CACHE HIT $(basename "$WALLPAPER") source=$MATUGEN_SRC — reloading visible themes only"
    write_manifest "cache-hit"
    reload_visible_themes
    timeout 1 notify-send -a matugen "Theme (cached)" "Visible apps reloaded. Starship updates on next prompt." 2>/dev/null || true
    exit 0
fi

THEME_START=$(date +%s)
RUN_LOG="$RUNS/$(date +%Y%m%d-%H%M%S)-$(basename "${WALLPAPER%.*}").log"

log "RUN $(basename "$WALLPAPER") source=$MATUGEN_SRC → $RUN_LOG"
echo ":: Matugen: Dark Standard (tonal-spot), source color 1 ($MATUGEN_SRC)"

{
    echo "=== matugen run $(date -Iseconds) ==="
    echo "wallpaper=$WALLPAPER"
    echo "source=$MATUGEN_SRC"
    echo "cache_key=$CACHE_KEY"
    echo "---"
    matugen color hex "$MATUGEN_SRC" \
        --mode dark \
        --type scheme-tonal-spot \
        --continue-on-error 2>&1 || true
    echo "--- exit=$?"
} | tee "$RUN_LOG" | tee -a "$LOG" >/dev/null

wait_for_priority_templates "$THEME_START"
reload_visible_themes
write_manifest "run"

primary=$(grep -m1 '^color_orange' "$STARSHIP_MATUGEN" 2>/dev/null || echo "ok")
log "DONE primary=$primary"
echo ":: Starship colors written ($primary)"

timeout 1 notify-send -a matugen "Theme updated" "Kitty + Hyprland + Waybar reloaded. Starship on next prompt." 2>/dev/null || true