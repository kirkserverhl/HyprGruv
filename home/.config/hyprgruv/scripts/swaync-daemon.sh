#!/usr/bin/env bash
# swaync-daemon.sh — start swaync with paths required for swaync-root installs
set -euo pipefail

root="${HOME}/.local/swaync-root"
schema_dir="${XDG_DATA_HOME:-$HOME/.local/share}/glib-2.0/schemas"
mkdir -p "$schema_dir"
if [[ -f "${root}/usr/share/glib-2.0/schemas/org.erikreider.swaync.gschema.xml" ]]; then
    cp -f "${root}/usr/share/glib-2.0/schemas/org.erikreider.swaync.gschema.xml" "$schema_dir/"
    glib-compile-schemas "$schema_dir" 2>/dev/null || true
fi
schema_dirs=(
    "$schema_dir"
    "${root}/usr/share/glib-2.0/schemas"
)

export GSETTINGS_SCHEMA_DIR
GSETTINGS_SCHEMA_DIR="$(IFS=:; echo "${schema_dirs[*]}")"
export XDG_CONFIG_DIRS="${root}/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}"

# Generated config (Zoho quiet hours) lives under state/; CSS/icons stay in the repo.
if [[ -x "$HOME/.hyprgruv/lib/scripts/zoho-notify-quiet.sh" ]]; then
    bash "$HOME/.hyprgruv/lib/scripts/zoho-notify-quiet.sh" --apply >/dev/null 2>&1 || true
fi
runtime_root="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/swaync-xdg"
if [[ -f "$runtime_root/swaync/config.json" ]]; then
    export XDG_CONFIG_HOME="$runtime_root"
fi

if [[ -x /usr/bin/swaync ]]; then
    exec /usr/bin/swaync "$@"
fi

if [[ -x "${root}/usr/bin/swaync" ]]; then
    exec "${root}/usr/bin/swaync" "$@"
fi

echo "swaync not found" >&2
exit 1