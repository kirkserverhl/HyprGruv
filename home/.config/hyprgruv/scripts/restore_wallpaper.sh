#!/bin/bash
# Login-only wallpaper restore.
#
# Restores the last wallpaper chosen via theme switcher (Super+W) or Waypaper.
# Priority matches what SDDM should show:
#   1. last_wallpaper.txt / settings/default  (source path of last choice)
#   2. default_wp.png                         (canonical PNG copy)
#   3. current theme entry in .wallpaper-state
#   4. waypaper config.ini (only if the file exists)
#   5. SDDM sugar-candy sddm-wallpaper.png    (last-resort copy)
#
# No waypaper post_command, no matugen, no palette popup on login.

set -uo pipefail

# shellcheck source=/home/kirk/.config/settings/default_wp.sh
source "$HOME/.config/settings/default_wp.sh"
# shellcheck source=/home/kirk/.config/settings/wallpaper-paths.sh
source "$HOME/.config/settings/wallpaper-paths.sh"

LOG=/tmp/restore_wallpaper.log
: >"$LOG"

log() {
	echo "[restore_wallpaper] $*" | tee -a "$LOG"
}

log "starting at $(date) WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}"

read_path_file() {
	local f="$1"
	[[ -f "$f" ]] || return 1
	local p
	p=$(tr -d '\r\n' <"$f")
	[[ -n "$p" && -f "$p" ]] || return 1
	printf '%s\n' "$p"
}

read_waypaper_config() {
	local ini="$HOME/.config/waypaper/config.ini" line p
	[[ -f "$ini" ]] || return 1
	line=$(grep -m1 '^wallpaper[[:space:]]*=' "$ini" 2>/dev/null | cut -d= -f2- || true)
	[[ -n "$line" ]] || return 1
	# trim + expand ~
	p="${line#"${line%%[![:space:]]*}"}"
	p="${p%"${p##*[![:space:]]}"}"
	p="${p//\"/}"
	if [[ "$p" == "~/"* ]]; then
		p="$HOME/${p:2}"
	fi
	[[ -f "$p" ]] || return 1
	printf '%s\n' "$p"
}

read_theme_wallpaper() {
	local theme state entry p
	theme=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme" 2>/dev/null || true)
	state="$HOME/.config/colorschemes/.wallpaper-state"
	[[ -n "$theme" && -f "$state" ]] || return 1
	entry=$(grep -m1 "^${theme}:" "$state" 2>/dev/null | cut -d: -f2- || true)
	[[ -n "$entry" ]] || return 1
	p="${entry#"${entry%%[![:space:]]*}"}"
	p="${p%"${p##*[![:space:]]}"}"
	[[ -f "$p" ]] || return 1
	printf '%s\n' "$p"
}

resolve_wallpaper() {
	local candidate=""

	# 1) Explicit last choice (theme switcher / waypaper post_command)
	if candidate=$(read_path_file "$CURRENT_WALLPAPER_FILE"); then
		printf '%s\n' "$candidate"
		return 0
	fi
	if candidate=$(read_path_file "$HOME/.config/settings/default"); then
		printf '%s\n' "$candidate"
		return 0
	fi

	# 2) Canonical PNG (kept in sync by set_wallpaper / AWWW_PERSIST)
	if [[ -n "${DEFAULT_WALLPAPER:-}" && -f "$DEFAULT_WALLPAPER" ]]; then
		printf '%s\n' "$DEFAULT_WALLPAPER"
		return 0
	fi

	# 3) Theme switcher per-theme state
	if candidate=$(read_theme_wallpaper); then
		printf '%s\n' "$candidate"
		return 0
	fi

	# 4) Waypaper config (only if path is a real file)
	if candidate=$(read_waypaper_config); then
		printf '%s\n' "$candidate"
		return 0
	fi

	# 5) SDDM copy — same image the greeter shows
	if [[ -f /usr/share/sddm/themes/sugar-candy/sddm-wallpaper.png ]]; then
		printf '%s\n' /usr/share/sddm/themes/sugar-candy/sddm-wallpaper.png
		return 0
	fi

	return 1
}

WP=$(resolve_wallpaper || true)
if [[ -z "$WP" ]]; then
	log "no wallpaper found (looked at last_wallpaper, default_wp, theme state, waypaper, SDDM); skipping"
	exit 0
fi

log "target: $WP"

# Ensure canonical default_wp exists so hyprlock/SDDM helpers stay aligned.
# Only create when missing — set_wallpaper / AWWW_PERSIST keep it current.
DEFAULT_WP_PNG="${DEFAULT_WALLPAPER:-$HOME/.config/settings/default_wp.png}"
if [[ ! -f "$DEFAULT_WP_PNG" && "$WP" != "$DEFAULT_WP_PNG" ]]; then
	mkdir -p "$(dirname "$DEFAULT_WP_PNG")" 2>/dev/null || true
	if command -v magick >/dev/null 2>&1; then
		magick "$WP" -strip -interlace none -quality 92 "$DEFAULT_WP_PNG" 2>/dev/null \
			|| cp -f "$WP" "$DEFAULT_WP_PNG" 2>/dev/null || true
	else
		cp -f "$WP" "$DEFAULT_WP_PNG" 2>/dev/null || true
	fi
	[[ -f "$DEFAULT_WP_PNG" ]] && log "created missing $DEFAULT_WP_PNG"
fi

# Keep last_wallpaper pointing at a real source when we recovered from SDDM/default_wp.
if [[ -n "${CURRENT_WALLPAPER_FILE:-}" ]]; then
	prev=""
	[[ -f "$CURRENT_WALLPAPER_FILE" ]] && prev=$(tr -d '\r\n' <"$CURRENT_WALLPAPER_FILE")
	if [[ -z "$prev" || ! -f "$prev" ]]; then
		# Prefer not to write SDDM/default_wp paths as "source" if we have theme state.
		if theme_wp=$(read_theme_wallpaper 2>/dev/null); then
			printf '%s\n' "$theme_wp" >"$CURRENT_WALLPAPER_FILE"
		elif [[ "$WP" != "$DEFAULT_WP_PNG" && "$WP" != /usr/share/sddm/* ]]; then
			printf '%s\n' "$WP" >"$CURRENT_WALLPAPER_FILE"
		fi
	fi
fi

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

if awww img --resize crop "$WP" >>"$LOG" 2>&1; then
	log "awww img ok"
else
	log "awww img failed — see $LOG"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true
log "done"