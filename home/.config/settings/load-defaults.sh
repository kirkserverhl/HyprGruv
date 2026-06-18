#!/usr/bin/env bash
# load-defaults.sh — export shell defaults from ~/.config/settings/*.sh
# Sourced by ~/.zshrc and ~/.bashrc

_settings_dir="${XDG_CONFIG_HOME:-$HOME/.config}/settings"

_hyprgruv_read_setting() {
    local name="$1"
    local fallback="${2:-}"
    local file="$_settings_dir/${name}.sh"
    local value=""

    if [[ -f "$file" ]]; then
        value="$(tr -d '[:space:]' <"$file")"
    fi

    [[ -n "$value" ]] || value="$fallback"
    printf '%s' "$value"
}

export TERMINAL="$(_hyprgruv_read_setting terminal kitty)"
export BROWSER="$(_hyprgruv_read_setting browser firefox)"
export EDITOR="$(_hyprgruv_read_setting editor nvim)"
export SUDO_EDITOR="$EDITOR"