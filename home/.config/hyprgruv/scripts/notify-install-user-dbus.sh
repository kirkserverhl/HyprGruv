#!/usr/bin/env bash
# Install user-session D-Bus service files for local swaync (no sudo).

set -euo pipefail

root="${HOME}/.local/swaync-root"
svc_dir="${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services"
swaync_bin="${root}/usr/bin/swaync"

[[ -x "$swaync_bin" ]] || exit 0
mkdir -p "$svc_dir"

cat >"$svc_dir/org.freedesktop.Notifications.service" <<EOF
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=${swaync_bin}
EOF

cat >"$svc_dir/org.erikreider.swaync.cc.service" <<EOF
[D-BUS Service]
Name=org.erikreider.swaync.cc
Exec=${swaync_bin}
EOF