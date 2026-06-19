#!/usr/bin/env bash
# colors-config.sh — save and load static color configurations (no wal/matugen re-extract)
#
# Set up once in the palette customizer, save a named config, load it later.
# While a config is active, wallpaper changes update the image only — colors stay frozen.
#
# Usage:
#   colors-config save <name> [--label "My setup"] [--from session|theme]
#   colors-config load <name> [--no-wallpaper]
#   colors-config list
#   colors-config show <name>
#   colors-config delete <name>
#   colors-config clear          # unload active config
#   colors-config current
#   colors-config pick           # interactive load (gum)

set -euo pipefail

CONFIG_DIR="$HOME/.config/colorschemes/configs"
ACTIVE_FILE="$HOME/.config/colorschemes/.active-config"
CURRENT_THEME_FILE="$HOME/.config/colorschemes/.current-theme"
USER_PALETTE="$HOME/.config/matugen/user-palette.json"
CACHE_DIR="$HOME/.cache/matugen"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER="$HOME/.config/hyprgruv/scripts/palette-build-import.py"
GENERATOR="$SCRIPT_DIR/generate-preset-colors.py"
RELOAD="$HOME/.config/hyprgruv/scripts/reload-matugen-visible.sh"
DEFAULT_WP="$HOME/Pictures/Wallpapers/gruvbox_image46.png"

mkdir -p "$CONFIG_DIR" "$CACHE_DIR"

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'
}

resolve_wallpaper() {
    local hint="${1:-}"
    if [[ -n "$hint" && -f "$hint" ]]; then
        echo "$hint"
        return
    fi
    for f in "$HOME/.config/last_wallpaper.txt" "$HOME/.config/settings/default"; do
        if [[ -f "$f" ]]; then
            local wp
            wp=$(tr -d '\n' <"$f")
            [[ -n "$wp" && -f "$wp" ]] && { echo "$wp"; return; }
        fi
    done
    if [[ -f "$DEFAULT_WP" ]]; then
        echo "$DEFAULT_WP"
        return
    fi
    echo ""
}

config_path() {
    local name="$1"
    echo "$CONFIG_DIR/$(slugify "$name").json"
}

active_config_name() {
    [[ -f "$ACTIVE_FILE" ]] || return 1
    local name
    name=$(tr -d '[:space:]' <"$ACTIVE_FILE")
    [[ -n "$name" ]] || return 1
    echo "$name"
}

apply_static_palette() {
    local theme="$1"
    local palette_src="$2"
    local wallpaper="${3:-}"
    local config_name="${4:-}"

    if [[ ! -f "$palette_src" ]]; then
        echo "colors-config: palette not found: $palette_src" >&2
        return 1
    fi

    if [[ -z "$wallpaper" ]]; then
        wallpaper=$(resolve_wallpaper "$(jq -r '.wallpaper // empty' "$palette_src" 2>/dev/null || true)")
    fi
    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        echo "colors-config: no wallpaper reference (kitty/matugen templates need an image path)" >&2
        return 1
    fi

    local theme_dir="$HOME/.config/colorschemes/$theme"
    mkdir -p "$theme_dir" "$CACHE_DIR"
    touch "$HOME/.config/colorschemes/.use-preset-colors"
    echo "$theme" >"$CURRENT_THEME_FILE"
    echo "preset:$theme" >"$CACHE_DIR/yazi-icon-mode"
    echo "saved" >"$CACHE_DIR/color-mode"

    if [[ -n "$config_name" ]]; then
        echo "$config_name" >"$ACTIVE_FILE"
    fi

    # Only mirror into the theme slot when this config belongs to that theme.
    src_theme=$(jq -r '.theme // empty' "$palette_src" 2>/dev/null || true)
    dest_palette="$theme_dir/palette.json"
    if [[ -z "$config_name" || -z "$src_theme" || "$src_theme" == "$theme" ]]; then
        src_real=$(readlink -f "$palette_src" 2>/dev/null || echo "$palette_src")
        dest_real=$(readlink -f "$dest_palette" 2>/dev/null || echo "$dest_palette")
        if [[ "$src_real" != "$dest_real" ]]; then
            cp -f "$palette_src" "$dest_palette"
        fi
    fi
    python3 - "$palette_src" "$USER_PALETTE" "$wallpaper" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

src_path, user_path, wallpaper = sys.argv[1:4]
data = json.loads(Path(src_path).read_text(encoding="utf-8"))
base16 = data.get("base16") or {}
clean = {}
for slot, val in base16.items():
    if isinstance(val, str) and val.startswith("#"):
        clean[slot.lower()] = val
payload = {
    "version": 1,
    "wallpaper": wallpaper,
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "source": "saved-config",
    "base16": clean,
}
Path(user_path).parent.mkdir(parents=True, exist_ok=True)
Path(user_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

    python3 "$GENERATOR" "$theme"

    local import_json="$CACHE_DIR/saved-import.json"
    python3 "$BUILDER" build-base16 "$palette_src" "$wallpaper" "$import_json"

    if command -v matugen >/dev/null 2>&1; then
        matugen image "$wallpaper" \
            --import-json "$import_json" \
            --source-color-index 0 \
            --continue-on-error 2>/dev/null || true
    fi

    jq -n \
        --arg wp "$wallpaper" \
        --arg theme "$theme" \
        --arg config "${config_name:-}" \
        '{
            wallpaper: $wp,
            method: "saved-config",
            color_mode: "saved",
            mode: "dark",
            type: "static-palette",
            theme: $theme,
            config: (if $config == "" then null else $config end)
        }' >"$CACHE_DIR/pending-run.json"

    cp -f "$theme_dir/palette.json" "$CACHE_DIR/current-palette.json" 2>/dev/null || true

    if [[ -x "$RELOAD" ]]; then
        "$RELOAD"
    fi

    echo "Applied static palette → $theme${config_name:+ (config: $config_name)}"
}

cmd_save() {
    local name="${1:-}"
    shift || true
    local label="" from="session"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --label)
                label="$2"
                shift 2
                ;;
            --from)
                from="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$name" ]]; then
        echo "Usage: colors-config save <name> [--label \"...\"] [--from session|theme]" >&2
        return 1
    fi

    local slug
    slug=$(slugify "$name")
    local out
    out="$CONFIG_DIR/${slug}.json"

    local src_palette=""
    local theme=""
    local wallpaper=""

    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        theme=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
    fi

    if [[ "$from" == "theme" && -n "$theme" && -f "$HOME/.config/colorschemes/$theme/palette.json" ]]; then
        src_palette="$HOME/.config/colorschemes/$theme/palette.json"
    elif [[ -f "$USER_PALETTE" ]] && jq -e '.base16 | length > 0' "$USER_PALETTE" >/dev/null 2>&1; then
        src_palette="$USER_PALETTE"
    elif [[ -n "$theme" && -f "$HOME/.config/colorschemes/$theme/palette.json" ]]; then
        src_palette="$HOME/.config/colorschemes/$theme/palette.json"
    else
        echo "colors-config: nothing to save — customize a palette first" >&2
        return 1
    fi

    wallpaper=$(resolve_wallpaper "$(jq -r '.wallpaper // empty' "$src_palette" 2>/dev/null || true)")

    [[ -z "$label" ]] && label="$name"

    python3 - "$src_palette" "$out" "$slug" "$label" "$theme" "$wallpaper" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

src_path, out_path, slug, label, theme, wallpaper = sys.argv[1:7]
data = json.loads(Path(src_path).read_text(encoding="utf-8"))
base16 = data.get("base16") or {}
clean = {}
for slot, val in base16.items():
    if isinstance(val, str) and val.startswith("#"):
        clean[slot.lower()] = val
if len(clean) < 8:
    raise SystemExit("need at least 8 base16 slots to save")

payload = {
    "version": 1,
    "name": slug,
    "label": label,
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "theme": theme or data.get("theme") or "",
    "wallpaper": wallpaper or data.get("wallpaper") or "",
    "source": "saved-config",
    "base16": clean,
}
spectrum = data.get("spectrum")
if isinstance(spectrum, dict):
    payload["spectrum"] = spectrum

Path(out_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(out_path)
PY

    echo "Saved configuration → $out"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a colorschemes "Config saved" "$label" -t 2500
    fi
}

cmd_load() {
    local name="${1:-}"
    shift || true
    local skip_wp=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-wallpaper)
                skip_wp=1
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$name" ]]; then
        echo "Usage: colors-config load <name> [--no-wallpaper]" >&2
        return 1
    fi

    local path
    path=$(config_path "$name")
    if [[ ! -f "$path" ]]; then
        echo "colors-config: not found: $name ($path)" >&2
        return 1
    fi

    local theme
    theme=$(jq -r '.theme // empty' "$path")
    if [[ -z "$theme" && -f "$CURRENT_THEME_FILE" ]]; then
        theme=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
    fi
    if [[ -z "$theme" ]]; then
        theme="coast-gruv"
    fi

    local wp=""
    wp=$(jq -r '.wallpaper // empty' "$path")
    wp=$(resolve_wallpaper "$wp")

    apply_static_palette "$theme" "$path" "$wp" "$(slugify "$name")"

    if [[ "$skip_wp" -eq 0 ]]; then
        local saved_wp
        saved_wp=$(jq -r '.wallpaper // empty' "$path")
        if [[ -n "$saved_wp" && -f "$saved_wp" ]]; then
            APPLY_MONITOR="all"
            [[ -f "$HOME/.config/colorschemes/.wallpaper-monitor" ]] && \
                APPLY_MONITOR=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.wallpaper-monitor")
            bash "$SCRIPT_DIR/awww-wallpaper.sh" "$saved_wp" "$APPLY_MONITOR" >/dev/null 2>&1 || true
        fi
    fi

    local label
    label=$(jq -r '.label // .name' "$path")
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a colorschemes "Config loaded" "$label" -t 3000
    fi
}

cmd_list() {
    if ! compgen -G "$CONFIG_DIR/*.json" >/dev/null; then
        echo "(no saved configurations)"
        return 0
    fi
    local active=""
    active=$(active_config_name 2>/dev/null || true)
    for f in "$CONFIG_DIR"/*.json; do
        local name label theme saved_at mark=""
        name=$(jq -r '.name // empty' "$f")
        label=$(jq -r '.label // .name' "$f")
        theme=$(jq -r '.theme // "—"' "$f")
        saved_at=$(jq -r '.saved_at // "?"' "$f" | cut -c1-19)
        [[ "$name" == "$active" ]] && mark=" *"
        printf "  %s%s  (%s)  theme=%s  saved=%s\n" "$label" "$mark" "$name" "$theme" "$saved_at"
    done
}

cmd_show() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: colors-config show <name>" >&2; return 1; }
    local path
    path=$(config_path "$name")
    [[ -f "$path" ]] || { echo "Not found: $name" >&2; return 1; }
    jq . "$path"
}

cmd_delete() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo "Usage: colors-config delete <name>" >&2; return 1; }
    local path slug
    slug=$(slugify "$name")
    path=$(config_path "$name")
    [[ -f "$path" ]] || { echo "Not found: $name" >&2; return 1; }
    rm -f "$path"
    if [[ "$(active_config_name 2>/dev/null || true)" == "$slug" ]]; then
        rm -f "$ACTIVE_FILE"
    fi
    echo "Deleted: $name"
}

cmd_clear() {
    rm -f "$ACTIVE_FILE"
    echo "saved" >"$CACHE_DIR/color-mode"
    echo "Active configuration cleared — theme palettes still apply statically until you re-sync."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a colorschemes "Config cleared" "Wallpaper changes won't re-extract while a theme preset is active." -t 3000
    fi
}

cmd_current() {
    if active=$(active_config_name 2>/dev/null); then
        path=$(config_path "$active")
        label=$(jq -r '.label // .name' "$path" 2>/dev/null || echo "$active")
        echo "Active: $label ($active)"
    else
        echo "No active saved configuration."
    fi
}

cmd_pick() {
    command -v gum >/dev/null 2>&1 || { echo "gum required for pick" >&2; return 1; }
    if ! compgen -G "$CONFIG_DIR/*.json" >/dev/null; then
        gum style --foreground 3 "No saved configurations yet."
        echo "Use the palette customizer → Save as named configuration"
        return 1
    fi

    local options=()
    local names=()
    for f in "$CONFIG_DIR"/*.json; do
        local label name
        label=$(jq -r '.label // .name' "$f")
        name=$(jq -r '.name' "$f")
        options+=("$label")
        names+=("$name")
    done
    options+=("Clear active configuration")
    options+=("Cancel")

    local choice
    choice=$(gum choose "${options[@]}" --header "Load color configuration") || return 0
    [[ "$choice" == "Cancel" || -z "$choice" ]] && return 0
    if [[ "$choice" == "Clear active configuration" ]]; then
        cmd_clear
        return 0
    fi

    local i
    for i in "${!options[@]}"; do
        if [[ "${options[$i]}" == "$choice" ]]; then
            cmd_load "${names[$i]}"
            return 0
        fi
    done
}

usage() {
    cat <<'EOF'
colors-config — save/load static color setups (no pywal or matugen re-extract)

  save <name> [--label "..."] [--from session|theme]
  load <name> [--no-wallpaper]
  list
  show <name>
  delete <name>
  clear
  current
  pick
EOF
}

main() {
    local cmd="${1:-}"
    shift || true
    case "$cmd" in
        save) cmd_save "$@" ;;
        load) cmd_load "$@" ;;
        list|ls) cmd_list ;;
        show) cmd_show "$@" ;;
        delete|rm) cmd_delete "$@" ;;
        clear) cmd_clear ;;
        current) cmd_current ;;
        pick) cmd_pick ;;
        apply-static)
            # internal: colors-config apply-static <theme> <palette.json> [config-name]
            apply_static_palette "${1:-}" "${2:-}" "${3:-}" "${4:-}"
            ;;
        -h|--help|help|"") usage ;;
        *)
            echo "Unknown command: $cmd" >&2
            usage >&2
            return 1
            ;;
    esac
}

main "$@"