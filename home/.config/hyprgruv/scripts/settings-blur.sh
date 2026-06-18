#!/usr/bin/env bash
# settings-blur.sh — rofi tuner for Hyprland decoration + layer blur
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY="$SCRIPT_DIR/apply-hypr-blur.sh"
CONF="${HYPR_BLUR_CONF:-$HOME/.config/settings/hypr-blur.conf}"
ROFI_CFG="$HOME/.config/rofi/config-compact.rasi"

# shellcheck source=/dev/null
source "$APPLY"

rofi_menu() {
    local prompt="$1"
    shift
    printf '%s\n' "$@" | rofi -dmenu -i -p "$prompt" -config "$ROFI_CFG" 2>/dev/null
}

float_choices() {
    local current="$1"
    local step="${2:-0.05}"
    awk -v cur="$current" -v step="$step" 'BEGIN {
        for (i = -4; i <= 4; i++) {
            v = cur + i * step
            if (v < 0) v = 0
            if (v > 1) v = 1
            printf "%.2f\n", v
        }
    }'
}

int_choices() {
    local current="$1"
    local min="${2:-0}"
    local max="${3:-32}"
    local v
    for delta in -8 -4 -2 -1 0 1 2 4 8; do
        v=$((current + delta))
        ((v < min)) && v=$min
        ((v > max)) && v=$max
        echo "$v"
    done | awk '!seen[$0]++'
}

adjust_int() {
    local key="$1"
    local label="$2"
    local min="${3:-0}"
    local max="${4:-32}"
    local current choice
    current=$(cfg_get "$key" 0)
    choice=$(int_choices "$current" "$min" "$max" | rofi_menu "$label (now: $current)") || return 0
    [[ -z "${choice:-}" ]] && return 0
    cfg_set "$key" "$choice"
    apply_hypr_blur
    notify-send "Blur" "$label → $choice"
}

adjust_float() {
    local key="$1"
    local label="$2"
    local step="${3:-0.05}"
    local current choice
    current=$(cfg_get "$key" 0)
    choice=$(float_choices "$current" "$step" | rofi_menu "$label (now: $current)") || return 0
    [[ -z "${choice:-}" ]] && return 0
    cfg_set "$key" "$choice"
    apply_hypr_blur
    notify-send "Blur" "$label → $choice"
}

toggle_enabled() {
    local current
    current=$(cfg_get decoration_enabled 1)
    if [[ "$current" == "1" ]]; then
        cfg_set decoration_enabled 0
        notify-send "Blur" "Window blur disabled"
    else
        cfg_set decoration_enabled 1
        notify-send "Blur" "Window blur enabled"
    fi
    apply_hypr_blur
}

layer_blur_label() {
    local key="$1"
    if layer_blur_enabled "$key"; then
        echo "on"
    else
        echo "off"
    fi
}

toggle_layer_blur() {
    local key="$1"
    local title="$2"
    if layer_blur_enabled "$key"; then
        cfg_set "layer_${key}_blur" 0
        notify-send "Blur" "$title layer blur disabled"
    else
        cfg_set "layer_${key}_blur" 1
        notify-send "Blur" "$title layer blur enabled"
    fi
    apply_hypr_blur
}

menu_global() {
    while true; do
        local choice
        choice=$(rofi_menu "Global window blur" \
            "Enabled: $(cfg_get decoration_enabled 1)" \
            "Size: $(cfg_get decoration_size 10)" \
            "Passes: $(cfg_get decoration_passes 3)" \
            "Noise: $(cfg_get decoration_noise 0.01)" \
            "Contrast: $(cfg_get decoration_contrast 0.8)" \
            "Vibrancy: $(cfg_get decoration_vibrancy 0.2)" \
            "← Back") || return 0
        [[ -z "${choice:-}" || "$choice" == "← Back" ]] && return 0
        case "$choice" in
        "Enabled:"*) toggle_enabled ;;
        "Size:"*) adjust_int decoration_size "Blur size" 0 32 ;;
        "Passes:"*) adjust_int decoration_passes "Blur passes" 0 12 ;;
        "Noise:"*) adjust_float decoration_noise "Blur noise" 0.01 ;;
        "Contrast:"*) adjust_float decoration_contrast "Blur contrast" 0.05 ;;
        "Vibrancy:"*) adjust_float decoration_vibrancy "Blur vibrancy" 0.05 ;;
        esac
    done
}

menu_layer() {
    local key="$1"
    local title="$2"
    while true; do
        local choice
        choice=$(rofi_menu "$title layer (strength = global blur)" \
            "Blur: $(layer_blur_label "$key")" \
            "Ignore alpha: $(cfg_get "layer_${key}_ignore_alpha" 0.10)" \
            "← Back") || return 0
        [[ -z "${choice:-}" || "$choice" == "← Back" ]] && return 0
        case "$choice" in
        "Blur:"*) toggle_layer_blur "$key" "$title" ;;
        "Ignore alpha:"*) adjust_float "layer_${key}_ignore_alpha" "$title ignore alpha" 0.01 ;;
        esac
    done
}

menu_hyprlock_bg() {
    while true; do
        local choice
        choice=$(rofi_menu "Hyprlock background blur" \
            "Passes: $(cfg_get hyprlock_bg_blur_passes 3)" \
            "Size: $(cfg_get hyprlock_bg_blur_size 2)" \
            "← Back") || return 0
        [[ -z "${choice:-}" || "$choice" == "← Back" ]] && return 0
        case "$choice" in
        "Passes:"*) adjust_int hyprlock_bg_blur_passes "Hyprlock passes" 0 12 ;;
        "Size:"*) adjust_int hyprlock_bg_blur_size "Hyprlock size" 0 16 ;;
        esac
    done
}

set_layer_blur_all() {
    local value="$1"
    for layer in rofi fuzzel waypaper wlogout hyprlock; do
        cfg_set "layer_${layer}_blur" "$value"
    done
}

apply_preset() {
    local name="$1"
    case "$name" in
    "Light")
        cfg_set decoration_enabled 1
        cfg_set decoration_size 6
        cfg_set decoration_passes 2
        cfg_set decoration_noise 0.01
        cfg_set decoration_contrast 0.75
        cfg_set decoration_vibrancy 0.15
        set_layer_blur_all 1
        cfg_set layer_rofi_ignore_alpha 0.12
        cfg_set layer_fuzzel_ignore_alpha 0.12
        cfg_set layer_waypaper_ignore_alpha 0.12
        cfg_set layer_wlogout_ignore_alpha 0.02
        cfg_set layer_hyprlock_ignore_alpha 0.08
        cfg_set hyprlock_bg_blur_passes 2
        cfg_set hyprlock_bg_blur_size 1
        ;;
    "Medium (default)")
        cfg_set decoration_enabled 1
        cfg_set decoration_size 10
        cfg_set decoration_passes 3
        cfg_set decoration_noise 0.01
        cfg_set decoration_contrast 0.8
        cfg_set decoration_vibrancy 0.2
        set_layer_blur_all 1
        cfg_set layer_rofi_ignore_alpha 0.10
        cfg_set layer_fuzzel_ignore_alpha 0.10
        cfg_set layer_waypaper_ignore_alpha 0.10
        cfg_set layer_wlogout_ignore_alpha 0.0001
        cfg_set layer_hyprlock_ignore_alpha 0.05
        cfg_set hyprlock_bg_blur_passes 3
        cfg_set hyprlock_bg_blur_size 2
        ;;
    "Heavy")
        cfg_set decoration_enabled 1
        cfg_set decoration_size 14
        cfg_set decoration_passes 4
        cfg_set decoration_noise 0.02
        cfg_set decoration_contrast 0.85
        cfg_set decoration_vibrancy 0.25
        set_layer_blur_all 1
        cfg_set layer_rofi_ignore_alpha 0.06
        cfg_set layer_fuzzel_ignore_alpha 0.06
        cfg_set layer_waypaper_ignore_alpha 0.06
        cfg_set layer_wlogout_ignore_alpha 0.0001
        cfg_set layer_hyprlock_ignore_alpha 0.03
        cfg_set hyprlock_bg_blur_passes 4
        cfg_set hyprlock_bg_blur_size 4
        ;;
    "Cinematic")
        cfg_set decoration_enabled 1
        cfg_set decoration_size 18
        cfg_set decoration_passes 5
        cfg_set decoration_noise 0.03
        cfg_set decoration_contrast 0.9
        cfg_set decoration_vibrancy 0.3
        set_layer_blur_all 1
        cfg_set layer_rofi_ignore_alpha 0.04
        cfg_set layer_fuzzel_ignore_alpha 0.04
        cfg_set layer_waypaper_ignore_alpha 0.04
        cfg_set layer_wlogout_ignore_alpha 0.0001
        cfg_set layer_hyprlock_ignore_alpha 0.02
        cfg_set hyprlock_bg_blur_passes 5
        cfg_set hyprlock_bg_blur_size 6
        ;;
    "Off")
        cfg_set decoration_enabled 0
        set_layer_blur_all 0
        cfg_set hyprlock_bg_blur_passes 0
        cfg_set hyprlock_bg_blur_size 0
        ;;
    esac
    apply_hypr_blur
    notify-send "Blur" "Preset: $name"
}

menu_presets() {
    local choice
    choice=$(rofi_menu "Blur presets" \
        "Light" \
        "Medium (default)" \
        "Heavy" \
        "Cinematic" \
        "Off" \
        "← Back") || return 0
    [[ -z "${choice:-}" || "$choice" == "← Back" ]] && return 0
    apply_preset "$choice"
}

show_status() {
    notify-send "Blur settings" \
        "Windows: enabled=$(cfg_get decoration_enabled 1) size=$(cfg_get decoration_size 10) passes=$(cfg_get decoration_passes 3)
Rofi: blur=$(layer_blur_label rofi) alpha=$(cfg_get layer_rofi_ignore_alpha 0.10)
Fuzzel: blur=$(layer_blur_label fuzzel) alpha=$(cfg_get layer_fuzzel_ignore_alpha 0.10)
Config: $CONF"
}

while true; do
    choice=$(rofi_menu "Blur tuner" \
        "Global window blur" \
        "Layer: Rofi" \
        "Layer: Fuzzel" \
        "Layer: Waypaper" \
        "Layer: Wlogout" \
        "Layer: Hyprlock" \
        "Hyprlock background" \
        "Presets" \
        "Re-apply saved" \
        "Show status" \
        "Exit") || exit 0

    [[ -z "${choice:-}" || "$choice" == "Exit" ]] && exit 0

    case "$choice" in
    "Global window blur") menu_global ;;
    "Layer: Rofi") menu_layer rofi "Rofi" ;;
    "Layer: Fuzzel") menu_layer fuzzel "Fuzzel" ;;
    "Layer: Waypaper") menu_layer waypaper "Waypaper" ;;
    "Layer: Wlogout") menu_layer wlogout "Wlogout" ;;
    "Layer: Hyprlock") menu_layer hyprlock "Hyprlock" ;;
    "Hyprlock background") menu_hyprlock_bg ;;
    "Presets") menu_presets ;;
    "Re-apply saved")
        apply_hypr_blur
        notify-send "Blur" "Re-applied saved settings"
        ;;
    "Show status") show_status ;;
    esac
done