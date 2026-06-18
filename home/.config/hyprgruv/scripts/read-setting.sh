#!/usr/bin/env bash
# read-setting.sh — read a one-line program default from ~/.config/settings/<name>.sh
set -euo pipefail

name="${1:?setting name required}"
fallback="${2:-}"
settings_file="${HOME}/.config/settings/${name}.sh"
value=""

if [[ -f "$settings_file" ]]; then
    value="$(tr -d '[:space:]' <"$settings_file")"
fi

[[ -n "$value" ]] || value="$fallback"
printf '%s\n' "$value"