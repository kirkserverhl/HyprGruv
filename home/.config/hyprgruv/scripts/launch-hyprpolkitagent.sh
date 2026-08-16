#!/usr/bin/env bash
# Start Hyprland's polkit authentication agent (single instance).
# plasma-desktop installs polkit-kde-agent; do not let both register.

set -euo pipefail

AGENT=/usr/lib/hyprpolkitagent/hyprpolkitagent
OTHER_AGENTS=(
	polkit-kde-authentication-agent-1
	polkit-gnome-authentication-agent-1
	polkit-mate-authentication-agent-1
	lxqt-policykit-agent
	xfce-polkit
	lxpolkit
)

install_kde_agent_guard() {
	local dest="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/plasma-polkit-agent.service.d"
	local src="${HYPRGRUV_DIR:-$HOME/.hyprgruv}/home/.config/systemd/user/plasma-polkit-agent.service.d/hyprland.conf"
	[[ -f "$src" ]] || return 0
	[[ -e "$dest/hyprland.conf" ]] && return 0
	mkdir -p "$dest"
	ln -sf "$src" "$dest/hyprland.conf"
	systemctl --user daemon-reload 2>/dev/null || true
}

if [[ ! -x "$AGENT" ]]; then
	echo "hyprpolkitagent not found at $AGENT" >&2
	exit 1
fi

install_kde_agent_guard

# Drop competing session agents so only hyprpolkitagent answers.
systemctl --user stop plasma-polkit-agent.service 2>/dev/null || true
for other in "${OTHER_AGENTS[@]}"; do
	if pgrep -x "$other" >/dev/null 2>&1; then
		pkill -x "$other" 2>/dev/null || true
	fi
done

if pgrep -f "$AGENT" >/dev/null 2>&1; then
	exit 0
fi

exec "$AGENT"