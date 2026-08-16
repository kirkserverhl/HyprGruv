#!/usr/bin/env bash
# window-opacity.sh — cycle the focused window through 5 even opacity steps.
#
# Super+O        lighter (more transparent): 100 → 85 → 70 → 60 → 50 → 100
# Super+Shift+O  darker  (more opaque):      50 → 60 → 70 → 85 → 100 → 50
#
#   low    0.50  Hyprland wiki / rice floor (readable with blur; below this
#                text contrast falls apart)
#   mid    rice  kitty background_opacity (0.70 here), or decoration:active
#                when that is already translucent
#   high   1.00  fully non-transparent
set -euo pipefail

direction="lighter"
case "${1:-}" in
    ""|--lighter|--light|--dec) direction="lighter" ;;
    --darker|--dark|--inc) direction="darker" ;;
    *)
        echo "usage: $0 [--lighter|--darker]" >&2
        exit 2
        ;;
esac

COMMUNITY_LOW="0.50"
SOLID="1.00"
KITTY_CONF="${HOME}/.config/kitty/kitty.conf"

notify() {
    local pct="$1" label="$2"
    notify-send -e -u low \
        -h string:x-canonical-private-synchronous:window-opacity \
        -h int:value:"$pct" \
        "Window opacity" "${pct}%${label}" 2>/dev/null || true
}

hypr_float() {
    hyprctl getoption "$1" -j 2>/dev/null | jq -r '.float // empty'
}

rice_opacity() {
    local kitty
    kitty="$(awk '/^[[:space:]]*background_opacity/ { print $2; exit }' "$KITTY_CONF" 2>/dev/null || true)"
    if [[ "$kitty" =~ ^0?\.[0-9]+$ || "$kitty" =~ ^1(\.0+)?$ ]]; then
        awk -v n="$kitty" 'BEGIN { printf "%.2f\n", n }'
        return
    fi
    printf '0.70\n'
}

lerp() {
    awk -v a="$1" -v b="$2" -v t="$3" 'BEGIN { printf "%.2f", a + (b - a) * t }'
}

active="$(hyprctl activewindow -j 2>/dev/null || true)"
if [[ -z "$active" || "$active" == "Invalid" ]] || ! grep -q '"address"' <<<"$active"; then
    notify-send -e -u low "Window opacity" "No focused window" 2>/dev/null || true
    exit 0
fi

system="$(hypr_float decoration:active_opacity)"
[[ -n "$system" ]] || system="1.0"

# Middle of the 5-step scale: live compositor opacity if the rice is already
# translucent, otherwise the terminal/system transparency (kitty 0.70).
if awk -v s="$system" 'BEGIN { exit !(s + 0 < 0.98) }'; then
    mid="$system"
else
    mid="$(rice_opacity)"
fi

# Keep the floor at or below mid so the scale always has room to dim.
low="$COMMUNITY_LOW"
if awk -v l="$low" -v m="$mid" 'BEGIN { exit !(l + 0 >= m + 0) }'; then
    low="$(lerp 0.35 "$mid" 0.5)"
fi

LEVELS=(
    "$(lerp "$low" "$low" 0)"
    "$(lerp "$low" "$mid" 0.5)"
    "$(awk -v m="$mid" 'BEGIN { printf "%.2f", m }')"
    "$(lerp "$mid" "$SOLID" 0.5)"
    "$(awk -v s="$SOLID" 'BEGIN { printf "%.2f", s }')"
)

current="$(hyprctl getprop activewindow opacity 2>/dev/null || true)"
[[ -n "$current" ]] || current="$SOLID"

idx=0
best=10000
i=0
for lvl in "${LEVELS[@]}"; do
    dist="$(awk -v a="$current" -v b="$lvl" 'BEGIN { d = a - b; if (d < 0) d = -d; printf "%d", d * 1000 }')"
    if ((dist < best)); then
        best="$dist"
        idx="$i"
    fi
    i=$((i + 1))
done

n="${#LEVELS[@]}"
if [[ "$direction" == "darker" ]]; then
    next="${LEVELS[$(((idx + 1) % n))]}"
else
    next="${LEVELS[$(((idx - 1 + n) % n))]}"
fi

set_prop() {
    local prop="$1" value="$2"
    hyprctl dispatch "hl.dsp.window.set_prop({ prop = \"${prop}\", value = \"${value}\" })" >/dev/null
}

set_prop opacity "$next"
set_prop opacity_inactive "$next"
set_prop opacity_fullscreen "$next"
set_prop opacity_override 1
set_prop opacity_inactive_override 1
set_prop opacity_fullscreen_override 1

pct="$(awk -v n="$next" 'BEGIN { printf "%d", n * 100 }')"
mid_pct="$(awk -v m="$mid" 'BEGIN { printf "%d", m * 100 }')"
label=""
if [[ "$pct" -eq "$mid_pct" ]]; then
    label=" · system"
elif [[ "$pct" -eq 100 ]]; then
    label=" · solid"
fi
notify "$pct" "$label"
