#!/bin/bash
# Login-only wallpaper restore.
#
# Uses ~/.config/settings/default_wp.png (same canonical copy SDDM uses).
# No waypaper post_command, no matugen, no palette popup on login.

set -uo pipefail

# shellcheck source=/home/kirk/.config/settings/default_wp.sh
source "$HOME/.config/settings/default_wp.sh"
# shellcheck source=/home/kirk/.config/settings/wallpaper-paths.sh
source "$HOME/.config/settings/wallpaper-paths.sh"

LOG=/tmp/restore_wallpaper.log

log() {
	echo "[restore_wallpaper] $*" | tee -a "$LOG"
}

log "starting at $(date) WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}"

resolve_wallpaper() {
	if [[ -f "$DEFAULT_WALLPAPER" ]]; then
		printf '%s\n' "$DEFAULT_WALLPAPER"
		return 0
	fi

	local candidate=""
	if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
		candidate=$(tr -d '\r\n' <"$CURRENT_WALLPAPER_FILE")
	elif [[ -f "$HOME/.config/settings/default" ]]; then
		candidate=$(tr -d '\r\n' <"$HOME/.config/settings/default")
	fi

	if [[ -n "$candidate" && -f "$candidate" ]]; then
		printf '%s\n' "$candidate"
		return 0
	fi

	return 1
}

WP=$(resolve_wallpaper || true)
if [[ -z "$WP" ]]; then
	log "no wallpaper found (expected $DEFAULT_WALLPAPER); skipping"
	exit 0
fi

log "target: $WP"

ensure_awww_daemon() {
	if awww query >>"$LOG" 2>&1; then
		log "awww already running"
		return 0
	fi

	if ! pgrep -x awww-daemon >/dev/null 2>&1; then
		log "starting awww-daemon"
		nohup awww-daemon >>"$LOG" 2>&1 &
		disown 2>/dev/null || true
	fi

	if ! pgrep -f "waypaper-engine.*daemon" >/dev/null 2>&1 && command -v waypaper-engine >/dev/null 2>&1; then
		log "starting waypaper-engine daemon"
		nohup waypaper-engine daemon >>"$LOG" 2>&1 &
		disown 2>/dev/null || true
	fi

	local i
	for i in $(seq 1 80); do
		if awww query >>"$LOG" 2>&1; then
			log "awww ready after ${i} checks"
			return 0
		fi
		sleep 0.25
	done

	log "awww not ready after 20s"
	return 1
}

ensure_awww_daemon || true

if awww img "$WP" >>"$LOG" 2>&1; then
	log "awww img ok"
else
	log "awww img failed — see $LOG"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true
log "done"