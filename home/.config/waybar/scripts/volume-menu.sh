#!/usr/bin/env bash
#
# volume-menu.sh
# Rofi dropdown menu for audio sinks/sources (left click on volume module)
# Right click should open pavucontrol (set in modules.json)
#
# Usage: bound as on-click on pulseaudio module in Waybar
#

set -euo pipefail

# Rofi config - reuse existing compact one for consistency
ROFI_CONFIG="~/.config/rofi/config-compact.rasi"

# Get current defaults
current_sink=$(pactl get-default-sink 2>/dev/null)
current_source=$(pactl get-default-source 2>/dev/null)

# Build menu
# Outputs (sinks)
sink_list=""
while read -r idx name driver _ _; do
    desc=$(pactl list sinks | sed -n "/Name: $name/,/^$/p" | grep -m1 "Description:" | cut -d: -f2- | xargs)
    [[ -z "$desc" ]] && desc="$name"
    marker=""
    if [[ "$name" == "$current_sink" ]]; then
        marker="  ✓"
    fi
    sink_list+=$"󰕾  ${desc}${marker} | sink | ${name}\n"
done < <(pactl list short sinks)

# Inputs (sources, exclude monitors)
source_list=""
while read -r idx name driver _ _; do
    if [[ "$name" == *".monitor" ]]; then
        continue
    fi
    desc=$(pactl list sources | sed -n "/Name: $name/,/^$/p" | grep -m1 "Description:" | cut -d: -f2- | xargs)
    [[ -z "$desc" ]] && desc="$name"
    marker=""
    if [[ "$name" == "$current_source" ]]; then
        marker="  ✓"
    fi
    source_list+=$"  ${desc}${marker} | source | ${name}\n"
done < <(pactl list short sources)

# Combine menu
menu=$(printf "%s\n%s\n" "$sink_list" "$source_list")

# Show rofi
chosen=$(echo "$menu" | rofi -dmenu -i \
    -p "Audio Device" \
    -config "$ROFI_CONFIG" \
    -no-fixed-num-lines \
    -width 45 \
    -lines 12 \
    -markup-rows)

[[ -z "${chosen:-}" ]] && exit 0

# Parse chosen
if [[ "$chosen" == *" | sink | "* ]]; then
    sink_name=$(echo "$chosen" | awk -F' | ' '{print $3}')
    pactl set-default-sink "$sink_name" 2>/dev/null || pamixer --set-default-sink "$sink_name"
    # Optional: move current streams to new sink
    for stream in $(pactl list sink-inputs short | awk '{print $1}'); do
        pactl move-sink-input "$stream" "$sink_name" 2>/dev/null || true
    done
    notify-send "Audio" "Switched output to: $sink_name" -t 1500
elif [[ "$chosen" == *" | source | "* ]]; then
    source_name=$(echo "$chosen" | awk -F' | ' '{print $3}')
    pactl set-default-source "$source_name" 2>/dev/null || pamixer --set-default-source "$source_name"
    # Move current mic streams if any
    for stream in $(pactl list source-outputs short | awk '{print $1}'); do
        pactl move-source-output "$stream" "$source_name" 2>/dev/null || true
    done
    notify-send "Audio" "Switched input to: $source_name" -t 1500
else
    # Fallback - shouldn't happen
    exit 0
fi
