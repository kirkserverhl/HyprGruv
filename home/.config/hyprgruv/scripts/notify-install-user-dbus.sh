#!/usr/bin/env bash
# Install user-session D-Bus service files for local swaync (no sudo).

set -euo pipefail

root="${HOME}/.local/swaync-root"
svc_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services"
daemon="${HOME}/.config/hyprgruv/scripts/swaync-daemon.sh"

[[ -x "$daemon" ]] || exit 0
[[ -x /usr/bin/swaync || -x "${root}/usr/bin/swaync" ]] || exit 0
mkdir -p "$svc_dir"

cat >"$svc_dir/org.freedesktop.Notifications.service" <<EOF
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=${daemon}
EOF

cat >"$svc_dir/org.erikreider.swaync.cc.service" <<EOF
[D-BUS Service]
Name=org.erikreider.swaync.cc
Exec=${daemon}
EOF