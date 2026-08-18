#!/usr/bin/env bash
# pick-theme-accent.sh — Super+W: source/primary color from theme palette
#
# Only choice after theme pick. Fast: list accents + rofi. Never applies themes.
# Magick swatches best-effort; text fallback if ImageMagick missing/busy.
#
# Usage:
#   pick-theme-accent.sh <theme-name> [wallpaper-path]
# Prints chosen #hex; exit 1 if cancelled (caller uses theme default).
# Writes user-accent + source-color for apply-theme standard assets.
set -euo pipefail

THEME="${1:-}"
WALLPAPER="${2:-}"
GENERATOR="${HOME}/.config/colorschemes/generate-preset-colors.py"
COLORSCHEMES="${HOME}/.config/colorschemes"
ROFI_THEME="${HOME}/.config/rofi/theme-accent-grid.rasi"
[[ -f "$ROFI_THEME" ]] || ROFI_THEME="${HOME}/.config/rofi/color-grid.rasi"

if [[ -z "$THEME" || ! -f "$GENERATOR" ]]; then
    echo "Usage: pick-theme-accent.sh <theme-name> [wallpaper-path]" >&2
    exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi not found" >&2
    exit 1
fi

# Never inherit a heavy rebuild path from the parent shell
unset THEME_SWITCHER_APPLY

PICKER_LABEL="Pick from wallpaper"
PICKER_SENTINEL="__hyprpicker__"
PICKER_CLASS="theme-source-picker"
PICKER_SPECIAL="sourcepick"
MPV_PID=""
OPENED_SPECIAL=0

resolve_wallpaper() {
    local wp="$1"
    if [[ -n "$wp" && -f "$wp" ]]; then
        printf '%s\n' "$wp"
        return 0
    fi
    local state="${COLORSCHEMES}/.wallpaper-state"
    if [[ -f "$state" ]]; then
        wp=$(grep "^${THEME}:" "$state" 2>/dev/null | cut -d':' -f2- || true)
        if [[ -n "$wp" && -f "$wp" ]]; then
            printf '%s\n' "$wp"
            return 0
        fi
    fi
    for f in "${HOME}/.config/last_wallpaper.txt" "${HOME}/.config/settings/default"; do
        if [[ -f "$f" ]]; then
            wp=$(tr -d '\n' <"$f")
            if [[ -n "$wp" && -f "$wp" ]]; then
                printf '%s\n' "$wp"
                return 0
            fi
        fi
    done
    return 1
}

special_visible() {
    hyprctl monitors -j 2>/dev/null | jq -e \
        --arg name "special:${PICKER_SPECIAL}" \
        '.[] | select((.specialWorkspace.name // "") == $name)' \
        >/dev/null
}

toggle_picker_special() {
    hyprctl dispatch "hl.dsp.workspace.toggle_special('${PICKER_SPECIAL}')" >/dev/null 2>&1 \
        || hyprctl dispatch togglespecialworkspace "$PICKER_SPECIAL" >/dev/null 2>&1 \
        || true
}

hide_picker_special() {
    local n=0
    while special_visible && [[ $n -lt 6 ]]; do
        toggle_picker_special
        n=$((n + 1))
        sleep 0.05
    done
}

cleanup_picker_image() {
    if [[ -n "${MPV_PID:-}" ]]; then
        kill "$MPV_PID" 2>/dev/null || true
        wait "$MPV_PID" 2>/dev/null || true
        MPV_PID=""
    fi
    pkill -f -- "--wayland-app-id=${PICKER_CLASS}" 2>/dev/null || true
    if [[ "${OPENED_SPECIAL:-0}" -eq 1 ]]; then
        hide_picker_special
        OPENED_SPECIAL=0
    fi
}

wait_for_picker_window() {
    local pid="$1" addr="" i
    for i in $(seq 1 60); do
        addr=$(hyprctl clients -j 2>/dev/null | jq -r --argjson pid "$pid" \
            '.[] | select(.pid == $pid) | .address' | head -1)
        if [[ -n "$addr" && "$addr" != "null" ]]; then
            printf '%s\n' "$addr"
            return 0
        fi
        sleep 0.05
    done
    return 1
}

wait_for_image_ready() {
    local addr="$1" i w h
    for i in $(seq 1 40); do
        read -r w h < <(hyprctl clients -j 2>/dev/null | jq -r --arg a "$addr" \
            '.[] | select(.address == $a) | "\(.size[0]) \(.size[1])"' | head -1)
        if [[ "${w:-0}" -gt 200 && "${h:-0}" -gt 200 ]]; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

force_fullscreen() {
    local addr="$1"
    # fullscreen / fullscreen 1 TOGGLE — use fullscreenstate to force on.
    hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1 || true
    hyprctl dispatch fullscreenstate 2 2 >/dev/null 2>&1 || \
        hyprctl dispatch "hl.dsp.window.fullscreen({ window = 'address:${addr}' })" >/dev/null 2>&1 || true
}

show_wallpaper_on_scratchpad() {
    local wp="$1" addr

    hyprctl --batch "keyword windowrulev2 workspace special:${PICKER_SPECIAL} silent,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 fullscreen,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 float,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 pin,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 noborder,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 noanim,class:^(${PICKER_CLASS})$ ; keyword windowrulev2 plugin:hyprbars:nobar,class:^(${PICKER_CLASS})$" \
        >/dev/null 2>&1 || true

    if ! special_visible; then
        OPENED_SPECIAL=1
    fi

    mpv --no-config --really-quiet --no-audio --no-terminal \
        --vo=gpu --hwdec=no --force-window=immediate --keep-open=yes \
        --loop-file=inf --image-display-duration=inf \
        --osd-level=0 --no-osc --cursor-autohide=no \
        --wayland-app-id="$PICKER_CLASS" \
        -- "$wp" >/dev/null 2>&1 &
    MPV_PID=$!

    addr=$(wait_for_picker_window "$MPV_PID" || true)
    if [[ -n "$addr" ]]; then
        hyprctl dispatch movetoworkspacesilent "special:${PICKER_SPECIAL},address:${addr}" >/dev/null 2>&1 || true
    fi

    if [[ "$OPENED_SPECIAL" -eq 1 ]] && ! special_visible; then
        toggle_picker_special
    fi

    if [[ -n "$addr" ]]; then
        force_fullscreen "$addr"
        # Pin so the image stays if hyprpicker steals focus and the special hides.
        local pinned
        pinned=$(hyprctl clients -j 2>/dev/null | jq -r --arg a "$addr" \
            '.[] | select(.address == $a) | .pinned' | head -1)
        if [[ "$pinned" != "true" ]]; then
            hyprctl dispatch pin "address:${addr}" >/dev/null 2>&1 || true
        fi
        wait_for_image_ready "$addr" || true
        force_fullscreen "$addr"
    fi

    # First decoded frame — do not start hyprpicker on a black window.
    sleep 0.35
}

pick_from_wallpaper() {
    local wp picked
    if ! wp=$(resolve_wallpaper "$WALLPAPER"); then
        notify-send "Theme" "No wallpaper to pick from" -u low 2>/dev/null || true
        return 1
    fi
    if ! command -v mpv >/dev/null 2>&1; then
        notify-send "Theme" "mpv is required to preview the wallpaper" -u low 2>/dev/null || true
        return 1
    fi

    show_wallpaper_on_scratchpad "$wp"
    # Live sample the pinned wallpaper. Do not -r freeze: that captured the
    # frame after special:scratchpad hid when hyprpicker took focus.
    picked=$(hyprpicker -f hex -l -q 2>/dev/null || true)
    cleanup_picker_image

    picked="${picked,,}"
    picked="${picked%%$'\n'*}"
    picked="${picked#"${picked%%[![:space:]]*}"}"
    picked="${picked%"${picked##*[![:space:]]}"}"
    if [[ "$picked" != \#* ]]; then
        picked="#${picked}"
    fi
    if [[ ! "$picked" =~ ^#[0-9a-f]{6}$ ]]; then
        return 1
    fi
    printf '%s\n' "$picked"
}

mapfile -t LINES < <(python3 "$GENERATOR" --list-accents "$THEME" 2>/dev/null | jq -c '.[]' 2>/dev/null || true)
if ((${#LINES[@]} == 0)); then
    echo "No accents for $THEME" >&2
    exit 1
fi

SWATCH_DIR=""
USE_ICONS=0
if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    SWATCH_DIR=$(mktemp -d /tmp/theme-accent-XXXXXX)
    USE_ICONS=1
fi
trap 'rm -rf "${SWATCH_DIR:-}" 2>/dev/null || true; cleanup_picker_image' EXIT

make_solid_swatch() {
    local hex="$1" dest="$2"
    if command -v magick >/dev/null 2>&1; then
        timeout 1 magick -size 112x112 "xc:${hex}" -alpha off png32:"$dest" 2>/dev/null || true
    else
        timeout 1 convert -size 112x112 "xc:${hex}" "$dest" 2>/dev/null || true
    fi
}

make_picker_swatch() {
    local dest="$1"
    local svg="" tmp
    for svg in \
        /usr/share/icons/Papirus-Dark/24x24@2x/actions/color-picker.svg \
        /usr/share/icons/Papirus-Dark/22x22@2x/actions/color-picker.svg \
        /usr/share/icons/Papirus-Dark/24x24/actions/color-picker.svg
    do
        [[ -f "$svg" ]] && break
        svg=""
    done

    if command -v magick >/dev/null 2>&1; then
        tmp="$SWATCH_DIR/picker-fg.png"
        if [[ -n "$svg" ]] && command -v rsvg-convert >/dev/null 2>&1; then
            timeout 1 rsvg-convert -w 64 -h 64 "$svg" -o "$tmp" 2>/dev/null || true
        fi
        if [[ -f "$tmp" ]]; then
            timeout 1 magick -size 112x112 \
                "gradient:#1e1e2e-#45475a" \
                \( "$tmp" \) -gravity center -composite \
                -alpha off png32:"$dest" 2>/dev/null || true
        else
            timeout 1 magick -size 112x112 \
                "gradient:#f38ba8-#89b4fa" \
                -alpha off png32:"$dest" 2>/dev/null || true
        fi
    elif command -v convert >/dev/null 2>&1; then
        timeout 1 convert -size 112x112 "gradient:#1e1e2e-#45475a" "$dest" 2>/dev/null || true
    fi
}

ROFI_INPUT=""
declare -a HEXES=()
declare -a LABELS=()
default_row=0
i=0
for line in "${LINES[@]}"; do
    hex=$(jq -r '.hex' <<<"$line")
    label=$(jq -r '.label' <<<"$line")
    is_default=$(jq -r '.default // false' <<<"$line")
    [[ -n "$hex" && "$hex" != "null" ]] || continue
    entry="${label}  ${hex}"
    HEXES+=("$hex")
    LABELS+=("$entry")
    if [[ "$is_default" == "true" ]]; then
        default_row=$i
    fi

    if [[ "$USE_ICONS" -eq 1 ]]; then
        swatch="$SWATCH_DIR/$(printf '%02d' "$i")-${label}.png"
        make_solid_swatch "$hex" "$swatch"
        if [[ -f "$swatch" ]]; then
            ROFI_INPUT+="${entry}\0icon\x1f${swatch}\n"
        else
            ROFI_INPUT+="${entry}\n"
        fi
    else
        ROFI_INPUT+="${entry}\n"
    fi
    i=$((i + 1))
done

((${#HEXES[@]})) || exit 1

# Last tile: open the chosen wallpaper fullscreen on the scratchpad, then hyprpicker
HEXES+=("$PICKER_SENTINEL")
LABELS+=("$PICKER_LABEL")
if [[ "$USE_ICONS" -eq 1 && -n "$SWATCH_DIR" ]]; then
    picker_swatch="$SWATCH_DIR/99-hyprpicker.png"
    make_picker_swatch "$picker_swatch"
    if [[ -f "$picker_swatch" ]]; then
        ROFI_INPUT+="${PICKER_LABEL}\0icon\x1f${picker_swatch}\n"
    else
        ROFI_INPUT+="${PICKER_LABEL}\n"
    fi
else
    ROFI_INPUT+="${PICKER_LABEL}\n"
fi

rofi_args=(
    -dmenu -i
    -p ""
    -mesg "Select Primary Color"
    -theme "$ROFI_THEME"
    -selected-row "$default_row"
    -no-custom
)
# Only request icons when we actually produced swatches
if [[ "$USE_ICONS" -eq 1 ]] && compgen -G "$SWATCH_DIR"/*.png >/dev/null 2>&1; then
    rofi_args+=(-show-icons)
fi

# Clear any leftover THEME_SWITCHER so rofi theme CSS is not blocked
chosen=$(printf '%b' "$ROFI_INPUT" | rofi "${rofi_args[@]}" 2>/dev/null || true)

# Esc / cancel → empty (caller uses theme default)
if [[ -z "${chosen:-}" ]]; then
    exit 1
fi

# Match label (with or without trailing "  #hex")
PICK_HEX=""
for i in "${!LABELS[@]}"; do
    if [[ "$chosen" == "${LABELS[$i]}" ]] || [[ "$chosen" == "${LABELS[$i]}"* ]]; then
        PICK_HEX="${HEXES[$i]}"
        break
    fi
done
if [[ -z "$PICK_HEX" ]]; then
    # bare hex paste / fallback
    cand=$(grep -oE '#[0-9a-fA-F]{6}' <<<"$chosen" | head -1 || true)
    [[ -n "$cand" ]] && PICK_HEX="${cand,,}"
fi
[[ -n "$PICK_HEX" ]] || exit 1

if [[ "$PICK_HEX" == "$PICKER_SENTINEL" ]]; then
    if ! command -v hyprpicker >/dev/null 2>&1; then
        notify-send "Theme" "hyprpicker is not installed" -u low 2>/dev/null || true
        exit 1
    fi
    if ! PICK_HEX=$(pick_from_wallpaper); then
        exit 1
    fi
fi

# Persist before any theme apply so apply-theme / generate-preset pick it up
mkdir -p "${COLORSCHEMES}/${THEME}"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/user-accent"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/source-color"

printf '%s\n' "$PICK_HEX"
exit 0
