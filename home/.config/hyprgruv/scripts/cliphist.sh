#!/usr/bin/env bash
# Split clipboard history: text vs screenshots (separate cliphist DBs).
#
#   cliphist.sh              text picker (default)
#   cliphist.sh text         text picker
#   cliphist.sh images       screenshot picker (thumbnails)
#   cliphist.sh d            delete from text
#   cliphist.sh w            wipe text
#   cliphist.sh images d     delete from screenshots
#   cliphist.sh images w     wipe screenshots

set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist"
TEXT_DB="${CACHE}/text.db"
IMAGE_DB="${CACHE}/db"
THUMB_DIR="${CACHE}/thumbs"
ROFI_TEXT="$HOME/.config/rofi/config-cliphist.rasi"
ROFI_IMAGES="$HOME/.config/rofi/config-cliphist-images.rasi"

mkdir -p "$CACHE"

mode="text"
action="pick"

for arg in "$@"; do
    case "$arg" in
    text | images) mode="$arg" ;;
    d | delete) action="delete" ;;
    w | wipe) action="wipe" ;;
    -h | --help)
        sed -n '2,11p' "$0"
        exit 0
        ;;
    *)
        echo "Usage: cliphist.sh [text|images] [d|w]" >&2
        exit 2
        ;;
    esac
done

if [[ "$mode" == "images" ]]; then
    db="$IMAGE_DB"
    rofi_conf="$ROFI_IMAGES"
    prompt="Screenshots"
    empty_msg="No screenshot clipboard history yet"
    rofi_icons=(-show-icons)
else
    db="$TEXT_DB"
    rofi_conf="$ROFI_TEXT"
    prompt="Text clipboard"
    empty_msg="No text clipboard history yet"
    rofi_icons=()
fi

clip() {
    cliphist -db-path "$db" "$@"
}

notify() {
    hyprctl notify 0 2200 0 "fontsize:13,$1" >/dev/null 2>&1 || true
}

list_raw() {
    clip list
}

pretty_image_label() {
    local preview=$1
    local body="${preview#\[\[ binary data }"
    body="${body% \]\]}"
    if [[ "$body" =~ ^([0-9.]+\ [A-Za-z]+)\ ([a-z0-9]+)\ ([0-9]+x[0-9]+)$ ]]; then
        printf '%s %s · %s' "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[1]}"
    else
        printf '%s' "$body"
    fi
}

make_thumb() {
    local line=$1
    local id="${line%%$'\t'*}"
    local thumb="${THUMB_DIR}/${id}.png"
    [[ -f "$thumb" ]] && return 0
    printf '%s\n' "$line" | clip decode 2>/dev/null \
        | magick - -thumbnail '128x128>' "$thumb" 2>/dev/null || true
}

prepare_image_thumbs() {
    mkdir -p "$THUMB_DIR"
    local line id n=0
    local -A live=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        id="${line%%$'\t'*}"
        live["$id"]=1
        make_thumb "$line" &
        n=$((n + 1))
        # Batch so first-open of a large store stays snappy.
        if ((n % 8 == 0)); then
            wait || true
        fi
    done
    wait || true

    local thumb stem
    for thumb in "$THUMB_DIR"/*.png; do
        [[ -e "$thumb" ]] || continue
        stem="${thumb##*/}"
        stem="${stem%.png}"
        if [[ -z "${live[$stem]+x}" ]]; then
            rm -f "$thumb"
        fi
    done
}

list_for_rofi() {
    if [[ "$mode" != "images" ]]; then
        list_raw
        return
    fi

    local tmp
    tmp="$(mktemp)"
    list_raw >"$tmp"
    prepare_image_thumbs <"$tmp"

    local line id preview thumb
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        id="${line%%$'\t'*}"
        preview="${line#*$'\t'}"
        thumb="${THUMB_DIR}/${id}.png"
        if [[ -f "$thumb" ]]; then
            printf '%s\t%s\0icon\x1f%s\n' "$id" "$(pretty_image_label "$preview")" "$thumb"
        else
            printf '%s\t%s\n' "$id" "$(pretty_image_label "$preview")"
        fi
    done <"$tmp"
    rm -f "$tmp"
}

pick_item() {
    local items
    items="$(list_raw || true)"
    if [[ -z "${items}" ]]; then
        notify "$empty_msg"
        return 1
    fi

    list_for_rofi | rofi -dmenu -replace -i \
        -config "$rofi_conf" \
        -p "$prompt" \
        -mesg "$prompt" \
        "${rofi_icons[@]}" || true
}

wipe_history() {
    # shellcheck source=/dev/null
    source "$HOME/.config/hyprgruv/scripts/hyprgruv-rofi-mnemonics.sh"
    if [ "$(hyprgruv_rofi_menu "" "$HOME/.config/rofi/config-short.rasi" "Clear" "Cancel")" = "Clear" ]; then
        clip wipe
        if [[ "$mode" == "images" ]]; then
            rm -rf "$THUMB_DIR"
        fi
    fi
}

case "$action" in
wipe)
    wipe_history
    ;;
delete)
    sel="$(pick_item || true)"
    [[ -z "${sel:-}" ]] && exit 0
    printf '%s\n' "$sel" | clip delete
    ;;
*)
    sel="$(pick_item || true)"
    [[ -z "${sel:-}" ]] && exit 0
    printf '%s\n' "$sel" | clip decode | wl-copy
    ;;
esac
