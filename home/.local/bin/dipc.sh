#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="${INPUT_DIR:-$HOME/Wallpapers}"
OUTPUT_BASE="${OUTPUT_BASE:-$HOME/themed-wallpapers}"
FORCE=0
SELECTED_THEME=""
COLORSCHEMES="${COLORSCHEMES:-$HOME/.config/colorschemes}"
DIPC_CACHE="${DIPC_CACHE:-$OUTPUT_BASE/.dipc-palettes}"

# theme_name|source|dipc_style
# source: builtin:<palette> or palette (reads $COLORSCHEMES/<theme>/palette.json)
THEMES=(
    "gruvbox-dark|builtin:gruvbox|Dark mode"
    "catppuccin|builtin:catppuccin|mocha"
    "nord-darker|builtin:nord|"
    "everforest-dark|builtin:everforest|Dark"
    "noir|palette|"
    "e-ink|palette|"
    "coast-gruv|palette|"
    "forest-night|palette|"
    "warm-stone|palette|"
)

usage() {
    cat <<EOF
Batch-apply dipc color filters to every wallpaper for theme preview.

Usage: $(basename "$0") [OPTIONS]

Options:
  -t, --theme NAME   Process one theme (see list below)
  -f, --force        Reprocess images even if output already exists
  -h, --help         Show this help

Environment:
  INPUT_DIR          Source wallpapers (default: ~/Wallpapers)
  OUTPUT_BASE        Preview output root (default: ~/themed-wallpapers)
  COLORSCHEMES       Theme palette directory (default: ~/.config/colorschemes)

Themes:
  gruvbox-dark, catppuccin, nord-darker, everforest-dark,
  noir, e-ink, coast-gruv, forest-night, warm-stone

Outputs land in \$OUTPUT_BASE/<theme>/ so you can review and copy keepers into
~/.config/colorschemes/<theme>/wallpapers/ when ready.
EOF
}

theme_names() {
    local entry theme_name
    for entry in "${THEMES[@]}"; do
        IFS='|' read -r theme_name _ _ <<<"$entry"
        printf '%s\n' "$theme_name"
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -t | --theme)
        SELECTED_THEME="${2:?--theme requires a name}"
        shift 2
        ;;
    -f | --force)
        FORCE=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
done

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Input directory not found: $INPUT_DIR" >&2
    exit 1
fi

if [[ -n "$SELECTED_THEME" ]]; then
    matched=0
    for entry in "${THEMES[@]}"; do
        IFS='|' read -r theme_name _ _ <<<"$entry"
        [[ "$theme_name" == "$SELECTED_THEME" ]] && matched=1
    done
    if [[ "$matched" -eq 0 ]]; then
        echo "Unknown theme: $SELECTED_THEME" >&2
        echo "Valid themes: $(theme_names | paste -sd, -)" >&2
        exit 1
    fi
fi

mapfile -t IMAGES < <(
    find "$INPUT_DIR" -path '*/.git/*' -prune -o \
        -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
        -print | sort
)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "No images found under $INPUT_DIR" >&2
    exit 1
fi

mkdir -p "$OUTPUT_BASE" "$DIPC_CACHE"

prepare_palette() {
    local theme_name="$1"
    local source="$2"
    local builtin_style="$3"
    local -n _palette_ref="$4"
    local -n _style_ref="$5"

    if [[ "$source" == builtin:* ]]; then
        _palette_ref="${source#builtin:}"
        _style_ref="$builtin_style"
        return 0
    fi

    local palette_json="$COLORSCHEMES/$theme_name/palette.json"
    if [[ ! -f "$palette_json" ]]; then
        echo "Missing palette for $theme_name: $palette_json" >&2
        return 1
    fi

    local dipc_json="$DIPC_CACHE/${theme_name}.json"
    python3 - "$palette_json" "$dipc_json" "$theme_name" <<'PY'
import json
import sys
from pathlib import Path

src, dest, theme = sys.argv[1:4]
data = json.loads(Path(src).read_text(encoding="utf-8"))
base16 = data.get("base16")
if not isinstance(base16, dict) or not base16:
    raise SystemExit(f"palette has no base16 block: {src}")
Path(dest).write_text(json.dumps({theme: base16}, indent=2) + "\n", encoding="utf-8")
PY

    _palette_ref="$dipc_json"
    _style_ref="$theme_name"
}

echo "Found ${#IMAGES[@]} images in $INPUT_DIR"
echo "Writing previews to $OUTPUT_BASE"
echo

for entry in "${THEMES[@]}"; do
    IFS='|' read -r theme_name source style <<<"$entry"

    if [[ -n "$SELECTED_THEME" && "$theme_name" != "$SELECTED_THEME" ]]; then
        continue
    fi

    output_dir="$OUTPUT_BASE/$theme_name"
    mkdir -p "$output_dir"

    palette=""
    palette_style=""
    if ! prepare_palette "$theme_name" "$source" "$style" palette palette_style; then
        echo "Skipping theme $theme_name (palette setup failed)" >&2
        continue
    fi

    if [[ "$source" == builtin:* ]]; then
        echo "Theme: $theme_name ($palette${palette_style:+, style: $palette_style}) -> $output_dir"
    else
        echo "Theme: $theme_name (custom palette) -> $output_dir"
    fi

    skipped=0
    failed=0
    processed=0
    failures_log="$OUTPUT_BASE/failures.log"

    for image in "${IMAGES[@]}"; do
        stem="${image##*/}"
        stem="${stem%.*}"

        if [[ "$FORCE" -eq 0 ]] && compgen -G "$output_dir/${stem}_*" >/dev/null; then
            ((skipped++)) || true
            continue
        fi

        ((processed++)) || true
        printf '  [%d] %s\n' "$processed" "${image##*/}"

        dipc_args=(--dir-output "$output_dir")
        if [[ -n "$palette_style" ]]; then
            dipc_args+=(--styles "$palette_style")
        fi

        if ! dipc "${dipc_args[@]}" "$palette" "$image" 2>>"$failures_log"; then
            ((failed++)) || true
            printf '%s | %s\n' "$theme_name" "$image" >>"$failures_log"
            echo "    failed (logged to failures.log)"
        fi
    done

    if [[ "$processed" -eq 0 ]]; then
        echo "  all ${#IMAGES[@]} images already processed (use --force to redo)"
    else
        echo "  finished: $((processed - failed)) ok, $failed failed, $skipped skipped"
    fi
    echo
done

echo "Done. Review $OUTPUT_BASE and copy your favorites into:"
echo "  ~/.config/colorschemes/<theme>/wallpapers/"