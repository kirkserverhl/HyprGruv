#!/usr/bin/env bash
# palette-cache.sh
#
# Scan your wallpapers and build a cache of "good" source colors
# that are known to work well with matugen.
#
# This is the "scan all the items and find compatible palettes in a cache folder"
# tool you described.
#
# Cache location: ~/.cache/matugen-palettes/
# Each wallpaper gets a small JSON file with its good source colors.
#
# Subcommands:
#   build          - scan all known wallpaper directories and (re)build cache
#   build-fast     - only scan new or changed wallpapers
#   clear          - delete the entire cache
#   stats          - show how many palettes are cached
#
# Later we can add a nice browser on top of this cache.

set -euo pipefail

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

CACHE_DIR="$HOME/.cache/matugen-palettes"
mkdir -p "$CACHE_DIR"

EXTRACTOR="$HOME/.config/hyprgruv/scripts/extract-good-source-colors.sh"

# Add/remove wallpaper directories here as needed
WALLPAPER_DIRS=(
    "$HOME/Pictures/Wallpapers"
    "$HOME/Pictures/walls-main"
    "$HOME/Documents/hyprcourse/Wallpapers"
    "$HOME/Downloads/walls-main"
)

log() { echo "[palette-cache] $*"; }

build_one() {
    local wp="$1"
    [[ -f "$wp" ]] || return 0

    local name
    name=$(basename "$wp")
    # Use a stable key (md5 of full path is fine and collision resistant enough)
    local key
    key=$(echo -n "$wp" | md5sum | cut -d' ' -f1)
    local out="$CACHE_DIR/${key}.json"

    # Skip if up-to-date (wallpaper mtime vs cache mtime)
    if [[ -f "$out" && "$out" -nt "$wp" ]]; then
        return 0
    fi

    local colors
    colors=$("$EXTRACTOR" "$wp" 6 2>/dev/null | head -6 | tr '\n' ' ' || true)

    if [[ -z "$colors" ]]; then
        colors="#4a5568 #718096 #a0aec0 #cbd5e0"
    fi

    # Store minimal useful info
    jq -n \
        --arg wallpaper "$wp" \
        --arg name "$name" \
        --argjson colors "$(echo "$colors" | jq -R 'split(" ") | map(select(. != ""))')" \
        --arg updated "$(date -Iseconds)" \
        '{wallpaper: $wallpaper, name: $name, good_source_colors: $colors, updated: $updated}' \
        > "$out"

    log "cached: $name"
}

cmd_build() {
    local count=0
    for dir in "${WALLPAPER_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        log "scanning: $dir"
        while IFS= read -r -d '' wp; do
            build_one "$wp"
            ((count++)) || true
            # gentle throttle so it doesn't hammer the machine
            if (( count % 50 == 0 )); then sleep 0.2; fi
        done < <(find "$dir" -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \) -print0 2>/dev/null)
    done
    log "done. cached palettes: $(find "$CACHE_DIR" -name '*.json' | wc -l)"
}

cmd_stats() {
    local total
    total=$(find "$CACHE_DIR" -name '*.json' | wc -l)
    echo "Cached palettes: $total"
    echo "Cache dir: $CACHE_DIR"
}

cmd_clear() {
    rm -rf "$CACHE_DIR"/*
    log "cache cleared"
}

case "${1:-}" in
    build|build-all) cmd_build ;;
    build-fast)      cmd_build ;;   # same for now; could add smarter logic later
    clear)           cmd_clear ;;
    stats)           cmd_stats ;;
    *)
        echo "Usage: $(basename "$0") {build | stats | clear}"
        echo
        echo "  build     Scan all wallpaper folders and (re)build the good-palette cache"
        echo "  stats     Show cache statistics"
        echo "  clear     Wipe the cache"
        exit 1
        ;;
esac
