#!/usr/bin/env bash
# apply-hypr-blur.sh — apply saved blur values from ~/.config/settings/hypr-blur.conf
# Hyprland 0.55+ Lua config: use hyprctl eval (keyword/layerrule keywords do not work).
set -euo pipefail

CONF="${HYPR_BLUR_CONF:-$HOME/.config/settings/hypr-blur.conf}"

cfg_get() {
    local key="$1"
    local default="${2:-}"
    local line value
    [[ -f "$CONF" ]] || {
        printf '%s' "$default"
        return 0
    }
    line=$(grep -E "^${key}=" "$CONF" 2>/dev/null | tail -1 || true)
    if [[ -z "$line" ]]; then
        printf '%s' "$default"
        return 0
    fi
    value="${line#*=}"
    value="${value%%#*}"
    value="${value// /}"
    printf '%s' "$value"
}

cfg_set() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$CONF")"
    touch "$CONF"
    if grep -qE "^${key}=" "$CONF" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONF"
    else
        printf '%s=%s\n' "$key" "$value" >>"$CONF"
    fi
}

hypr_eval() {
    hyprctl eval "$1"
}

layer_blur_enabled() {
    local key="$1"
    local blur passes size
    blur=$(cfg_get "layer_${key}_blur" "")
    if [[ -n "$blur" ]]; then
        [[ "$blur" == "1" ]]
        return
    fi
    passes=$(cfg_get "layer_${key}_passes" "4")
    size=$(cfg_get "layer_${key}_size" "8")
    [[ "$passes" != "0" && "$size" != "0" ]]
}

apply_layer_rule() {
    local rule_name="$1"
    local namespace="$2"
    local order="$3"
    local key="$4"
    local alpha_default="$5"
    shift 5
    local extra="${*:-}"

    local alpha blur_flag
    alpha=$(cfg_get "layer_${key}_ignore_alpha" "$alpha_default")
    if layer_blur_enabled "$key"; then
        blur_flag="true"
    else
        blur_flag="false"
    fi

    hypr_eval "hl.layer_rule({
  name = '${rule_name}',
  match = { namespace = '${namespace}' },
  blur = ${blur_flag},
  blur_popups = ${blur_flag},
  ignore_alpha = ${alpha},
  order = ${order}${extra}
})"
}

apply_decoration() {
    local enabled size passes noise contrast vibrancy
    enabled=$(cfg_get decoration_enabled 1)
    size=$(cfg_get decoration_size 10)
    passes=$(cfg_get decoration_passes 3)
    noise=$(cfg_get decoration_noise 0.01)
    contrast=$(cfg_get decoration_contrast 0.8)
    vibrancy=$(cfg_get decoration_vibrancy 0.2)

    local enabled_flag="true"
    [[ "$enabled" == "0" ]] && enabled_flag="false"

    hypr_eval "hl.config({
  decoration = {
    blur = {
      enabled = ${enabled_flag},
      size = ${size},
      passes = ${passes},
      noise = ${noise},
      contrast = ${contrast},
      vibrancy = ${vibrancy},
    },
  },
})"
}

apply_layers() {
    apply_layer_rule "rofi-blur" "^rofi$" 50 rofi 0.10
    apply_layer_rule "fuzzel-blur" "^(fuzzel|launcher)$" 50 fuzzel 0.10
    apply_layer_rule "waypaper-blur" "^waypaper$" 50 waypaper 0.10
    apply_layer_rule "wlogout-blur" "^wlogout$" 200 wlogout 0.0001 \
        ", dim_around = true, xray = true"
    apply_layer_rule "hyprlock-blur" "^hyprlock$" 150 hyprlock 0.05
}

apply_hyprlock_conf() {
    local lock_conf="$HOME/.config/hypr/hyprlock/hyprlock.conf"
    local passes size
    passes=$(cfg_get hyprlock_bg_blur_passes 3)
    size=$(cfg_get hyprlock_bg_blur_size 2)
    [[ -f "$lock_conf" ]] || return 0
    sed -i -E \
        -e "s/^[[:space:]]*blur_passes[[:space:]]*=.*/    blur_passes = ${passes}/" \
        -e "s/^[[:space:]]*blur_size[[:space:]]*=.*/    blur_size = ${size}/" \
        "$lock_conf"
}

force_blur_refresh() {
    hyprctl dispatch focuscurrentorlast >/dev/null 2>&1 || true
}

apply_hypr_blur() {
    command -v hyprctl >/dev/null 2>&1 || {
        echo "[ERROR] hyprctl not found — run inside Hyprland" >&2
        return 1
    }

    apply_decoration
    apply_layers
    apply_hyprlock_conf
    force_blur_refresh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-apply}" in
    apply)
        apply_hypr_blur
        ;;
    get)
        cfg_get "${2:?key}" "${3:-}"
        ;;
    set)
        cfg_set "${2:?key}" "${3:?value}"
        apply_hypr_blur
        ;;
    *)
        echo "Usage: apply-hypr-blur.sh [apply|get KEY [DEFAULT]|set KEY VALUE]" >&2
        exit 1
        ;;
    esac
fi