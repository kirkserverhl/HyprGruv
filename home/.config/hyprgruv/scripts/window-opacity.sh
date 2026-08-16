#!/usr/bin/env bash
# window-opacity.sh — cycle window opacity through 5 even steps.
#
# Super+O        all workspaces on the focused monitor, lighter:
#                100 → 85 → 70 → 60 → 50 → 100
# Super+Shift+O  same windows, darker:
#                50 → 60 → 70 → 85 → 100 → 50
#
# Scope is the 2-per-screen workspace pair (plus any extra workspaces
# currently on that output). Scratchpad is left alone.
# Omit --monitor to cycle only the focused window.
#
#   low    0.50  Hyprland wiki / rice floor (readable with blur; below this
#                text contrast falls apart)
#   mid    rice  kitty background_opacity (0.70 here), or decoration:active
#                when that is already translucent
#   high   1.00  fully non-transparent
set -euo pipefail

direction="lighter"
scope="window"
usage() {
    echo "usage: $0 [--lighter|--darker] [--monitor]" >&2
    exit 2
}

for arg in "$@"; do
    case "$arg" in
        --lighter|--light|--dec) direction="lighter" ;;
        --darker|--dark|--inc) direction="darker" ;;
        --monitor|--all) scope="monitor" ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

COMMUNITY_LOW="0.50"
SOLID="1.00"
KITTY_CONF="${HOME}/.config/kitty/kitty.conf"

notify() {
    local title="$1" pct="$2" label="$3"
    notify-send -e -u low \
        -h string:x-canonical-private-synchronous:window-opacity \
        -h int:value:"$pct" \
        "$title" "${pct}%${label}" 2>/dev/null || true
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
has_active=0
if [[ -n "$active" && "$active" != "Invalid" ]] && grep -q '"address"' <<<"$active"; then
    has_active=1
fi

if [[ "$scope" == "window" && "$has_active" -eq 0 ]]; then
    notify-send -e -u low "Window opacity" "No focused window" 2>/dev/null || true
    exit 0
fi

if [[ "$has_active" -eq 1 ]]; then
    monitor="$(jq -r '.monitor // empty' <<<"$active")"
    focus_addr="$(jq -r '.address // empty' <<<"$active")"
else
    monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .id' | head -n1)"
    focus_addr=""
fi

if [[ "$scope" == "monitor" ]]; then
    if [[ -z "$monitor" ]]; then
        notify-send -e -u low "Monitor opacity" "No focused monitor" 2>/dev/null || true
        exit 0
    fi
    workspaces="$(hyprctl workspaces -j 2>/dev/null || true)"
    clients="$(hyprctl clients -j 2>/dev/null || true)"
    ws_ids="$(jq -c --argjson mon "$monitor" '
        [ .[] | select(.monitorID == $mon and .id > 0) | .id ]
    ' <<<"$workspaces")"
    mapfile -t addrs < <(jq -r --argjson wss "${ws_ids:-[]}" '
        .[]
        | select(.mapped == true and .hidden == false and (.workspace.id as $id | $wss | index($id) != null))
        | .address
    ' <<<"$clients")
    if [[ "${#addrs[@]}" -eq 0 ]]; then
        notify-send -e -u low "Monitor opacity" "No windows on this monitor's workspaces" 2>/dev/null || true
        exit 0
    fi
else
    addrs=("$focus_addr")
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

# Step from a window that is actually in the target set so a focused
# scratchpad (or other excluded window) cannot yank the whole screen.
current_addr="${addrs[0]}"
if [[ -n "$focus_addr" ]]; then
    for addr in "${addrs[@]}"; do
        if [[ "$addr" == "$focus_addr" ]]; then
            current_addr="$focus_addr"
            break
        fi
    done
fi
current="$(hyprctl getprop "address:${current_addr}" opacity 2>/dev/null || true)"
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

batch=""
for addr in "${addrs[@]}"; do
    win="address:${addr}"
    for prop in opacity opacity_inactive opacity_fullscreen; do
        batch+="dispatch hl.dsp.window.set_prop({ prop = \"${prop}\", value = \"${next}\", window = \"${win}\" });"
        batch+="dispatch hl.dsp.window.set_prop({ prop = \"${prop}_override\", value = \"1\", window = \"${win}\" });"
    done
done
hyprctl --batch "${batch%;}" >/dev/null

pct="$(awk -v n="$next" 'BEGIN { printf "%d", n * 100 }')"
mid_pct="$(awk -v m="$mid" 'BEGIN { printf "%d", m * 100 }')"
label=""
if [[ "$pct" -eq "$mid_pct" ]]; then
    label=" · system"
elif [[ "$pct" -eq 100 ]]; then
    label=" · solid"
fi

if [[ "$scope" == "monitor" ]]; then
    count="${#addrs[@]}"
    if [[ "$count" -eq 1 ]]; then
        notify "Monitor opacity" "$pct" "${label} · 1 window"
    else
        notify "Monitor opacity" "$pct" "${label} · ${count} windows"
    fi
else
    notify "Window opacity" "$pct" "$label"
fi
