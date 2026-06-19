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

KITTY_COLORS="$HOME/.config/kitty/colors/custom/matugen.conf"
HYPR_COLORS="$HOME/.config/hypr/colors/custom/matugen.conf"
STARSHIP_MATUGEN="$HOME/.config/starship/matugen-rainbow.toml"
STARSHIP_ACTIVE="$HOME/.config/starship.toml"
WAYBAR_COLORS="$HOME/.config/waybar/colors/matugen-waybar.css"

MATUGEN_MODE="dark"
MATUGEN_TYPE="scheme-tonal-spot"
MATUGEN_METHOD="hex"
SOURCE_INDEX=0
THEME_RAN=0
THEME_OK=0
APPLY_LOCK_DIR="$CACHE_DIR/apply.lock.d"

mkdir -p "$CACHE_DIR" "$RUNS"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

reload_visible_themes() {
    "$SCRIPTS/reload-matugen-visible.sh" 2>/dev/null || true
}

on_exit() {
    release_apply_lock 2>/dev/null || true
    if [[ "$THEME_OK" -eq 1 ]]; then
        reload_visible_themes || true
    fi
}
trap on_exit EXIT

# One apply at a time (mkdir lock — safe against fd inheritance by dunst post_hooks).
acquire_apply_lock() {
    local waited=0
    while ! mkdir "$APPLY_LOCK_DIR" 2>/dev/null; do
        if [[ "$waited" -eq 0 ]]; then
            log "Waiting for previous matugen apply to finish..."
        fi
        sleep 0.15
        waited=$((waited + 1))
        if [[ "$waited" -gt 600 ]]; then
            log "WARNING: stale apply lock — clearing $APPLY_LOCK_DIR"
            rmdir "$APPLY_LOCK_DIR" 2>/dev/null || true
            waited=0
        fi
    done
}

release_apply_lock() {
    rmdir "$APPLY_LOCK_DIR" 2>/dev/null || true
}

acquire_apply_lock

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
    # Default; explicit rofi picks override to hex below (must match swatch hex).
    MATUGEN_METHOD="hex"

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

STYLE_CHOSEN=0
if [[ -n "${MATUGEN_ARGS:-}" ]]; then
    parse_matugen_args "$MATUGEN_ARGS"
    STYLE_CHOSEN=1
    log "Using MATUGEN_ARGS: $MATUGEN_ARGS (source=$MATUGEN_SRC)"
elif interactive_ok; then
    log "Showing palette chooser for $(basename "$WALLPAPER")"
    if chosen=$("$CHOOSER" "$WALLPAPER" 2>/dev/null); then
        parse_matugen_args "$chosen"
        STYLE_CHOSEN=1
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

# Persistent grayscale only when palette.sh set force-monochrome.
# Explicit rofi choice (Standard/Vibrant) must clear the flag *before* we read it.
if [[ "$STYLE_CHOSEN" -eq 1 ]]; then
    if [[ "$MATUGEN_TYPE" != "scheme-monochrome" ]]; then
        rm -f "$CACHE_DIR/force-monochrome" 2>/dev/null || true
    fi
elif [[ -f "$CACHE_DIR/force-monochrome" ]]; then
    MATUGEN_TYPE="scheme-monochrome"
    log "palette.sh monochrome active (force-monochrome)"
fi

# Rofi swatches come from extract-good-source-colors.sh; matugen image
# --source-color-index uses a different internal ranking — always apply the
# exact hex the user picked so the theme matches the preview.
if [[ "$STYLE_CHOSEN" -eq 1 ]]; then
    MATUGEN_METHOD="hex"
fi

WP_MTIME=$(stat -c %Y "$WALLPAPER" 2>/dev/null || echo 0)
CACHE_KEY="${WALLPAPER}|${MATUGEN_METHOD}|${MATUGEN_MODE}|${MATUGEN_TYPE}|${SOURCE_INDEX}|${MATUGEN_SRC}|${WP_MTIME}"

priority_files_ok() {
    [[ -s "$KITTY_COLORS" && -s "$HYPR_COLORS" && -s "$STARSHIP_MATUGEN" && -s "$WAYBAR_COLORS" ]]
}

# Detect legacy starship layouts (posthook fallback / base16 remap) that left empty
# colored wedges before git/lang/docker segments.
starship_format_stale() {
    [[ -f "$STARSHIP_MATUGEN" ]] || return 0
    if grep -q 'auto-generated via posthook' "$STARSHIP_MATUGEN" 2>/dev/null; then
        return 0
    fi
    awk '/^format = """$/,/^"""$/' "$STARSHIP_MATUGEN" 2>/dev/null | grep -qE \
        'fg:color_(yellow bg:color_aqua|aqua bg:color_blue|blue bg:color_bg3|bg3 bg:color_bg1)' \
        && return 0
    return 1
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
    [[ "$STYLE_CHOSEN" -eq 1 ]] && return 1
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

if cache_hit && ! starship_format_stale; then
    log "CACHE HIT $(basename "$WALLPAPER") source=$MATUGEN_SRC — reloading visible themes only"
    THEME_RAN=1
    THEME_OK=1
    write_manifest "cache-hit"
    timeout 1 notify-send -a matugen -r 9001 "Theme applied" "Palette reloaded from cache. Starship updates on next prompt." 2>/dev/null || true
    exit 0
fi

if cache_hit && starship_format_stale; then
    log "CACHE HIT but starship prompt layout is stale — regenerating templates"
fi

THEME_START=$(date +%s)
RUN_LOG="$RUNS/$(date +%Y%m%d-%H%M%S)-$(basename "${WALLPAPER%.*}").log"
THEME_RAN=1

# Posthook reads this to build current.json with the same matugen invocation (not a
# separate hex pass that can desync or false-trigger grayscale on dark gruv walls).
jq -n \
    --arg wp "$WALLPAPER" \
    --arg method "$MATUGEN_METHOD" \
    --arg mode "$MATUGEN_MODE" \
    --arg type "$MATUGEN_TYPE" \
    --arg source_hex "$MATUGEN_SRC" \
    --argjson source_index "${SOURCE_INDEX:-0}" \
    '{
        wallpaper: $wp,
        method: $method,
        mode: $mode,
        type: $type,
        source_hex: $source_hex,
        source_index: $source_index
    }' > "$CACHE_DIR/pending-run.json"

if [[ "$MATUGEN_METHOD" == "image" ]]; then
    echo "matugen" >"$CACHE_DIR/yazi-icon-mode"
fi

run_matugen_logged() {
    local -a cmd=("$@")
    local tmp exit_code

    tmp=$(mktemp /tmp/matugen-run-XXXXXX.log)
    {
        echo "=== matugen run $(date -Iseconds) ==="
        echo "wallpaper=$WALLPAPER"
        echo "cache_key=$CACHE_KEY"
        echo "---"
        # Post-hooks used to block on notify-send; cap total runtime as a safety net.
        timeout 180 "${cmd[@]}" 2>&1 || true
        exit_code=$?
        echo "--- exit=$exit_code"
    } > "$tmp"

    cat "$tmp" | tee "$RUN_LOG" | tee -a "$LOG" >/dev/null
    rm -f "$tmp"
    return "$exit_code"
}

set +e
matugen_exit=0
if [[ "$MATUGEN_METHOD" == "image" ]]; then
    log "RUN $(basename "$WALLPAPER") image mode index=$SOURCE_INDEX source=$MATUGEN_SRC → $RUN_LOG"
    echo ":: Matugen: $MATUGEN_MODE / $MATUGEN_TYPE, source color $((SOURCE_INDEX + 1)) ($MATUGEN_SRC)"
    run_matugen_logged matugen image "$WALLPAPER" \
        --mode "$MATUGEN_MODE" \
        --type "$MATUGEN_TYPE" \
        --source-color-index "$SOURCE_INDEX" \
        --continue-on-error || matugen_exit=$?
else
    log "RUN $(basename "$WALLPAPER") hex source=$MATUGEN_SRC → $RUN_LOG"
    echo ":: Matugen: $MATUGEN_MODE / $MATUGEN_TYPE, source ($MATUGEN_SRC)"
    run_matugen_logged matugen color hex "$MATUGEN_SRC" \
        --mode "$MATUGEN_MODE" \
        --type "$MATUGEN_TYPE" \
        --continue-on-error || matugen_exit=$?
fi
set -e

if ! wait_for_priority_templates "$THEME_START"; then
    log "WARNING: priority templates not fully refreshed (matugen exit=$matugen_exit)"
fi

if priority_files_ok; then
    THEME_OK=1
    # Hex mode does not pass a reliable {{image}} to matugen run_after — sync caches here.
    "$HOME/.local/bin/matugen-posthook" "$WALLPAPER" 2>/dev/null || true
    write_manifest "run"
    primary=$(grep -m1 '^color_orange' "$STARSHIP_MATUGEN" 2>/dev/null | sed -E "s/.*= *['\"]?([^'\"]+)['\"]?.*/\1/" || echo "unknown")
    log "DONE primary=$primary source=$MATUGEN_SRC"
    echo ":: Theme applied (primary accent: $primary)"
    timeout 1 notify-send -a matugen -r 9001 "Theme applied" "Palette updated. Hyprland, Waybar, and app themes reloaded." 2>/dev/null || true
else
    log "ERROR: matugen did not refresh priority templates for $(basename "$WALLPAPER") (exit=$matugen_exit)"
    echo ":: Theme apply failed — colors may still be from the previous wallpaper" >&2
    timeout 1 notify-send -a matugen -r 9001 -u critical "Theme failed" "Palette did not apply. Try again or check ~/.cache/matugen/matugen.log" 2>/dev/null || true
fi