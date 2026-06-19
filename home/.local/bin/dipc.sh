#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="${INPUT_DIR:-$HOME/Wallpapers}"
OUTPUT_BASE="${OUTPUT_BASE:-$HOME/themed-wallpapers}"
FORCE=0
SELECTED_THEME=""

# name|dipc_palette|dipc_style  (empty style = palette default)
THEMES=(
    "gruvbox-dark|gruvbox|Dark mode"
    "catppuccin|catppuccin|mocha"
    "nord|nord|"
    "everforest-dark|everforest|Dark"
)

usage() {
    cat <<EOF
Batch-apply dipc color filters to every wallpaper for theme preview.

Usage: $(basename "$0") [OPTIONS]

Options:
  -t, --theme NAME   Process one theme (gruvbox-dark, catppuccin, nord, everforest-dark)
  -f, --force        Reprocess images even if output already exists
  -h, --help         Show this help

Environment:
  INPUT_DIR          Source wallpapers (default: ~/Wallpapers)
  OUTPUT_BASE        Preview output root (default: ~/themed-wallpapers)

Outputs land in \$OUTPUT_BASE/<theme>/ so you can review and copy keepers into
~/.config/colorschemes/<theme>/wallpapers/ when ready.
EOF
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
        echo "Valid themes: gruvbox-dark, catppuccin, nord, everforest-dark" >&2
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

mkdir -p "$OUTPUT_BASE"

echo "Found ${#IMAGES[@]} images in $INPUT_DIR"
echo "Writing previews to $OUTPUT_BASE"
echo

for entry in "${THEMES[@]}"; do
    IFS='|' read -r theme_name palette style <<<"$entry"

    if [[ -n "$SELECTED_THEME" && "$theme_name" != "$SELECTED_THEME" ]]; then
        continue
    fi

    output_dir="$OUTPUT_BASE/$theme_name"
    mkdir -p "$output_dir"

    echo "Theme: $theme_name ($palette${style:+, style: $style}) -> $output_dir"

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
        if [[ -n "$style" ]]; then
            dipc_args+=(--styles "$style")
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