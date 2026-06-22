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

if [[ -x /usr/bin/swaync ]]; then
    exec /usr/bin/swaync "$@"
fi

if [[ -x "${root}/usr/bin/swaync" ]]; then
    exec "${root}/usr/bin/swaync" "$@"
fi

echo "swaync not found" >&2
exit 1