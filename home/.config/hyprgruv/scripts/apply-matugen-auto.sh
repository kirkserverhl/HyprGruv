#!/usr/bin/env bash
# apply-matugen-auto.sh — matugen apply with optional palette chooser + logging
#
# Usage: apply-matugen-auto.sh [/path/to/wallpaper.png]
#
# Env:
#   MATUGEN_FORCE=1           skip cache and regenerate all templates
#   MATUGEN_CACHE=0             same as MATUGEN_FORCE=1
#   MATUGEN_NONINTERACTIVE=1    skip rofi palette chooser (auto-pick source color 1)
#   MATUGEN_ARGS="..."          pre-set matugen flags (skips chooser)

set -euo pipefail

WALLPAPER="${1:-}"
SCRIPTS="$HOME/.config/hyprgruv/scripts"
CACHE_DIR="$HOME/.cache/matugen"
MANIFEST="$CACHE_DIR/last-run.json"
LOG="$CACHE_DIR/matugen.log"
RUNS="$CACHE_DIR/runs"
EXTRACTOR="$SCRIPTS/extract-good-source-colors.sh"
CHOOSER="$SCRIPTS/rofi-choose-matugen-style.sh"

KITTY_COLORS="$HOME/.config/kitty/colors.conf"
HYPR_COLORS="$HOME/.config/hypr/colors/custom/matugen.conf"
STARSHIP_MATUGEN="$HOME/.config/starship/matugen-rainbow.toml"
STARSHIP_ACTIVE="$HOME/.config/starship.toml"
WAYBAR_COLORS="$HOME/.config/waybar/colors/matugen-waybar.css"

MATUGEN_MODE="dark"
MATUGEN_TYPE="scheme-tonal-spot"
MATUGEN_METHOD="hex"
SOURCE_INDEX=0
THEME_RAN=0

mkdir -p "$CACHE_DIR" "$RUNS"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

reload_visible_themes() {
    "$SCRIPTS/reload-matugen-visible.sh" 2>/dev/null || true
}

on_exit() {
    if [[ "$THEME_RAN" -eq 1 ]]; then
        reload_visible_themes || true
    fi
}
trap on_exit EXIT

if [[ -z "$WALLPAPER" ]]; then
    # shellcheck source=/home/kirk/.config/settings/wallpaper-paths.sh
    source "$HOME/.config/settings/wallpaper-paths.sh"
    [[ -f "$CURRENT_WALLPAPER_FILE" ]] && WALLPAPER=$(cat "$CURRENT_WALLPAPER_FILE")
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

# Build candidate source colors (used for cache key + hex fallback)
mapfile -t GOOD_COLORS < <(
    if [[ -x "$EXTRACTOR" ]]; then
        "$EXTRACTOR" "$WALLPAPER" 4 2>/dev/null || true
    fi
)
if [[ ${#GOOD_COLORS[@]} -eq 0 ]]; then
    GOOD_COLORS=("#a78a9d")
fi

MATUGEN_SRC="${GOOD_COLORS[0]}"

interactive_ok() {
    [[ "${MATUGEN_NONINTERACTIVE:-0}" == "1" ]] && return 1
    [[ -n "${MATUGEN_ARGS:-}" ]] && return 1
    [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] || return 1
    command -v rofi >/dev/null 2>&1 || return 1
    [[ -x "$CHOOSER" ]] || return 1
    return 0
}

parse_matugen_args() {
    local args="$1"
    local -a parts
    local i=0

    MATUGEN_MODE="dark"
    MATUGEN_TYPE="scheme-tonal-spot"
    SOURCE_INDEX=0
    MATUGEN_METHOD="image"

    read -r -a parts <<< "$args"
    while [[ $i -lt ${#parts[@]} ]]; do
        case "${parts[$i]}" in
            --mode)
                i=$((i + 1))
                MATUGEN_MODE="${parts[$i]:-dark}"
                ;;
            --mode=*)
                MATUGEN_MODE="${parts[$i]#--mode=}"
                ;;
            --type)
                i=$((i + 1))
                MATUGEN_TYPE="${parts[$i]:-scheme-tonal-spot}"
                ;;
            --type=*)
                MATUGEN_TYPE="${parts[$i]#--type=}"
                ;;
            --source-color-index)
                i=$((i + 1))
                SOURCE_INDEX="${parts[$i]:-0}"
                ;;
            --source-color-index=*)
                SOURCE_INDEX="${parts[$i]#--source-color-index=}"
                ;;
        esac
        i=$((i + 1))
    done

    SOURCE_INDEX="${SOURCE_INDEX//[^0-9]/}"
    [[ -z "$SOURCE_INDEX" ]] && SOURCE_INDEX=0
    if [[ "$SOURCE_INDEX" -ge ${#GOOD_COLORS[@]} ]]; then
        SOURCE_INDEX=$((${#GOOD_COLORS[@]} - 1))
    fi
    MATUGEN_SRC="${GOOD_COLORS[$SOURCE_INDEX]}"
}

if [[ -n "${MATUGEN_ARGS:-}" ]]; then
    parse_matugen_args "$MATUGEN_ARGS"
    log "Using MATUGEN_ARGS: $MATUGEN_ARGS (source=$MATUGEN_SRC)"
elif interactive_ok; then
    log "Showing palette chooser for $(basename "$WALLPAPER")"
    if chosen=$("$CHOOSER" "$WALLPAPER" 2>/dev/null); then
        parse_matugen_args "$chosen"
        log "User chose: mode=$MATUGEN_MODE type=$MATUGEN_TYPE index=$SOURCE_INDEX source=$MATUGEN_SRC"
    else
        log "Palette chooser cancelled — using auto source color 1 ($MATUGEN_SRC)"
        MATUGEN_METHOD="hex"
        SOURCE_INDEX=0
        MATUGEN_SRC="${GOOD_COLORS[0]}"
    fi
else
    log "Non-interactive — auto source color 1 ($MATUGEN_SRC)"
fi

WP_MTIME=$(stat -c %Y "$WALLPAPER" 2>/dev/null || echo 0)
CACHE_KEY="${WALLPAPER}|${MATUGEN_METHOD}|${MATUGEN_MODE}|${MATUGEN_TYPE}|${SOURCE_INDEX}|${MATUGEN_SRC}|${WP_MTIME}"

priority_files_ok() {
    [[ -s "$KITTY_COLORS" && -s "$HYPR_COLORS" && -s "$STARSHIP_MATUGEN" && -s "$WAYBAR_COLORS" ]]
}

write_manifest() {
    local mode="${1:-run}"
    local primary="${2:-}"
    if [[ -z "$primary" && -f "$STARSHIP_MATUGEN" ]]; then
        primary=$(grep -m1 '^color_orange' "$STARSHIP_MATUGEN" 2>/dev/null | sed -E "s/.*= *['\"]?([^'\"]+)['\"]?.*/\1/" || true)
    fi
    jq -n \
        --arg wp "$WALLPAPER" \
        --arg src "$MATUGEN_SRC" \
        --arg key "$CACHE_KEY" \
        --arg primary "${primary:-}" \
        --arg mode "$mode" \
        --arg matugen_mode "$MATUGEN_MODE" \
        --arg matugen_type "$MATUGEN_TYPE" \
        --argjson source_index "${SOURCE_INDEX:-0}" \
        --argjson mtime "${WP_MTIME:-0}" \
        --arg at "$(date -Iseconds)" \
        '{
            wallpaper: $wp,
            source_hex: $src,
            cache_key: $key,
            wallpaper_mtime: $mtime,
            primary: $primary,
            mode: $mode,
            matugen_mode: $matugen_mode,
            matugen_type: $matugen_type,
            source_index: $source_index,
            ran_at: $at
        }' > "$MANIFEST"
}

cache_hit() {
    [[ "${MATUGEN_FORCE:-0}" == "1" || "${MATUGEN_CACHE:-1}" == "0" ]] && return 1
    [[ -f "$MANIFEST" ]] || return 1
    priority_files_ok || return 1
    local key
    key=$(jq -r '.cache_key // empty' "$MANIFEST" 2>/dev/null || true)
    [[ "$key" == "$CACHE_KEY" ]]
}

wait_for_priority_templates() {
    local start_ts="$1"
    local f mtime
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
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
    THEME_RAN=1
    write_manifest "cache-hit"
    timeout 1 notify-send -a matugen "Theme (cached)" "Visible apps reloaded. Starship updates on next prompt." 2>/dev/null || true
    exit 0
fi

THEME_START=$(date +%s)
RUN_LOG="$RUNS/$(date +%Y%m%d-%H%M%S)-$(basename "${WALLPAPER%.*}").log"
THEME_RAN=1

run_matugen_logged() {
    local -a cmd=("$@")
    local tmp exit_code

    tmp=$(mktemp /tmp/matugen-run-XXXXXX.log)
    {
        echo "=== matugen run $(date -Iseconds) ==="
        echo "wallpaper=$WALLPAPER"
        echo "cache_key=$CACHE_KEY"
        echo "---"
        "${cmd[@]}" 2>&1 || true
        exit_code=$?
        echo "--- exit=$exit_code"
    } > "$tmp"

    cat "$tmp" | tee "$RUN_LOG" | tee -a "$LOG" >/dev/null
    rm -f "$tmp"
}

if [[ "$MATUGEN_METHOD" == "image" ]]; then
    log "RUN $(basename "$WALLPAPER") image mode index=$SOURCE_INDEX source=$MATUGEN_SRC → $RUN_LOG"
    echo ":: Matugen: $MATUGEN_MODE / $MATUGEN_TYPE, source color $((SOURCE_INDEX + 1)) ($MATUGEN_SRC)"
    run_matugen_logged matugen image "$WALLPAPER" \
        --mode "$MATUGEN_MODE" \
        --type "$MATUGEN_TYPE" \
        --source-color-index "$SOURCE_INDEX" \
        --continue-on-error
else
    log "RUN $(basename "$WALLPAPER") hex source=$MATUGEN_SRC → $RUN_LOG"
    echo ":: Matugen: $MATUGEN_MODE / $MATUGEN_TYPE, auto source ($MATUGEN_SRC)"
    run_matugen_logged matugen color hex "$MATUGEN_SRC" \
        --mode "$MATUGEN_MODE" \
        --type "$MATUGEN_TYPE" \
        --continue-on-error
fi

set +e
wait_for_priority_templates "$THEME_START"
write_manifest "run"
primary=$(grep -m1 '^color_orange' "$STARSHIP_MATUGEN" 2>/dev/null | sed -E "s/.*= *['\"]?([^'\"]+)['\"]?.*/\1/" || echo "unknown")
set -e

log "DONE primary=$primary"
echo ":: Theme applied (primary accent: $primary)"

timeout 1 notify-send -a matugen "Theme updated" "Palette applied. Hyprland borders + Waybar reloaded." 2>/dev/null || true