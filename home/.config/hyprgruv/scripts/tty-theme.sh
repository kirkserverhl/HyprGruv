#!/usr/bin/env bash
# ===================================================================
# tty-theme.sh — Linux virtual console (TTY) 16-color palette via setvtrgb
#
# Affects VTs (Ctrl+Alt+F3 …) and the console after leaving Hyprland.
# Does NOT recolor early kernel / Plymouth boot messages.
#
# setvtrgb needs access to the console device → usually root from a graphical
# session. Prefer: install the system unit once (sudo), then every boot is automatic.
#
# Usage:
#   tty-theme.sh                         # Omarchy gruvbox (default)
#   tty-theme.sh omarchy-gruvbox
#   tty-theme.sh matugen                 # map from matugen (best-effort)
#   tty-theme.sh --install-system-unit   # sudo: persist palette on every boot
#   tty-theme.sh --print
# ===================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/tty"
OMARCHY_VTRGB="$TTY_DIR/omarchy-gruvbox.vtrgb"
SYSTEM_VTRGB="/etc/vtrgb-omarchy-gruvbox"
SYSTEM_UNIT="/etc/systemd/system/vtrgb-omarchy-gruvbox.service"

# Omarchy gruvbox — basecamp/omarchy themes/gruvbox/colors.toml (quattro)
# Soft Gruvbox Material–style palette (not classic morhetz hard dark).
OMARCHY_HEX=(
	'#1e1e1e' # 0  black  (dark_background)
	'#ea6962' # 1  red
	'#a9b665' # 2  green
	'#d8a657' # 3  yellow
	'#7daea3' # 4  blue / accent
	'#d3869b' # 5  magenta
	'#89b482' # 6  cyan
	'#bdae93' # 7  white (light_foreground)
	'#665c54' # 8  bright black (muted)
	'#ea6962' # 9  bright red
	'#a9b665' # 10 bright green
	'#d8a657' # 11 bright yellow
	'#7daea3' # 12 bright blue
	'#d3869b' # 13 bright magenta
	'#89b482' # 14 bright cyan
	'#d4be98' # 15 bright white (foreground)
)

usage() {
	sed -n '2,16p' "$0" | sed 's/^# \?//'
}

write_hex_vtrgb() {
	local out=$1
	shift
	local -a hex=("$@")
	local i
	: >"$out"
	for i in $(seq 0 15); do
		local h="${hex[$i]}"
		h="${h#\#}"
		printf '#%s\n' "$h" >>"$out"
	done
}

ensure_omarchy_file() {
	mkdir -p "$TTY_DIR"
	write_hex_vtrgb "$OMARCHY_VTRGB" "${OMARCHY_HEX[@]}"
}

run_setvtrgb() {
	local file=$1
	if ! command -v setvtrgb >/dev/null 2>&1; then
		echo "setvtrgb not found (package: kbd)" >&2
		return 1
	fi

	# Graphical sessions usually need root + an explicit console device.
	local -a tries=(
		"setvtrgb $file"
		"setvtrgb -C /dev/tty0 $file"
		"setvtrgb -C /dev/console $file"
	)
	local cmd
	for cmd in "${tries[@]}"; do
		# shellcheck disable=SC2086
		if $cmd 2>/dev/null; then
			echo ":: TTY palette applied: $file"
			return 0
		fi
	done

	if command -v sudo >/dev/null 2>&1; then
		if sudo -n setvtrgb -C /dev/tty0 "$file" 2>/dev/null \
			|| sudo setvtrgb -C /dev/tty0 "$file" 2>/dev/null; then
			echo ":: TTY palette applied (via sudo): $file"
			return 0
		fi
	fi

	echo "Could not apply palette (need root for /dev/tty0 from a graphical session)." >&2
	echo "Install once so it runs at boot:" >&2
	echo "  $0 --install-system-unit" >&2
	return 1
}

apply_omarchy() {
	ensure_omarchy_file
	run_setvtrgb "$OMARCHY_VTRGB"
}

apply_matugen() {
	local JSON_CACHE="$HOME/.cache/matugen/current.json"
	local SHELL_CACHE="$HOME/.cache/matugen/colors.sh"
	declare -A COLORS

	if [[ ! -f "$JSON_CACHE" && ! -f "$SHELL_CACHE" ]]; then
		echo "No matugen cache — use: $0 omarchy-gruvbox" >&2
		return 1
	fi

	if [[ -f "$JSON_CACHE" ]] && command -v jq >/dev/null 2>&1; then
		while IFS='=' read -r key val; do
			[[ -n "$key" ]] && COLORS["$key"]="$val"
		done < <(jq -r '
			.colors.default
			| to_entries[]
			| "COLOR_" + (.key | ascii_upcase | gsub("-"; "_")) + "=" + .value.hex
		' "$JSON_CACHE" 2>/dev/null || true)
	elif [[ -f "$SHELL_CACHE" ]]; then
		# shellcheck disable=SC1090
		source "$SHELL_CACHE"
		local var
		for var in $(compgen -v | grep '^COLOR_' || true); do
			COLORS["$var"]="${!var}"
		done
	fi

	get_color() {
		local name=$1 fallback=$2
		local c="${COLORS[$name]:-$fallback}"
		c="${c#\#}"
		echo "#$c"
	}

	local hex=(
		"$(get_color COLOR_SURFACE 1e1e1e)"
		"$(get_color COLOR_ERROR ea6962)"
		"$(get_color COLOR_TERTIARY a9b665)"
		"$(get_color COLOR_PRIMARY d8a657)"
		"$(get_color COLOR_SECONDARY 7daea3)"
		"$(get_color COLOR_SECONDARY d3869b)"
		"$(get_color COLOR_TERTIARY 89b482)"
		"$(get_color COLOR_ON_SURFACE bdae93)"
		"$(get_color COLOR_SURFACE_CONTAINER_HIGH 665c54)"
		"$(get_color COLOR_ERROR ea6962)"
		"$(get_color COLOR_TERTIARY a9b665)"
		"$(get_color COLOR_PRIMARY d8a657)"
		"$(get_color COLOR_SECONDARY 7daea3)"
		"$(get_color COLOR_SECONDARY d3869b)"
		"$(get_color COLOR_TERTIARY 89b482)"
		"$(get_color COLOR_ON_SURFACE d4be98)"
	)

	local tmp
	tmp=$(mktemp /tmp/matugen-vtrgb.XXXXXX)
	write_hex_vtrgb "$tmp" "${hex[@]}"
	run_setvtrgb "$tmp"
	local rc=$?
	rm -f "$tmp"
	return "$rc"
}

install_system_unit() {
	ensure_omarchy_file
	if ! command -v sudo >/dev/null 2>&1; then
		echo "sudo required to install system unit" >&2
		return 1
	fi

	echo ":: Installing $SYSTEM_VTRGB and $SYSTEM_UNIT (sudo)…"
	sudo install -Dm644 "$OMARCHY_VTRGB" "$SYSTEM_VTRGB"
	sudo tee "$SYSTEM_UNIT" >/dev/null <<EOF
[Unit]
Description=Apply Omarchy gruvbox palette to Linux virtual consoles
Documentation=man:setvtrgb(8)
After=systemd-vconsole-setup.service
Before=getty.target

[Service]
Type=oneshot
ExecStart=/usr/bin/setvtrgb -C /dev/tty0 $SYSTEM_VTRGB
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
	sudo systemctl daemon-reload
	sudo systemctl enable --now vtrgb-omarchy-gruvbox.service
	echo ":: System unit enabled — TTY palette applies on every boot"
	echo ":: Also applied for this session (if sudo succeeded above)"
}

# Disable failed user unit from earlier attempt (no console access as user)
disable_user_unit_if_present() {
	local u="hyprgruv-tty-theme.service"
	if systemctl --user cat "$u" >/dev/null 2>&1; then
		systemctl --user disable --now "$u" 2>/dev/null || true
		rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$u"
		rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/graphical-session.target.wants/$u"
		systemctl --user daemon-reload 2>/dev/null || true
	fi
}

cmd="${1:-omarchy-gruvbox}"

case "$cmd" in
	-h | --help | help)
		usage
		exit 0
		;;
	--print | print)
		ensure_omarchy_file
		echo "palette: omarchy-gruvbox (Omarchy soft gruvbox / material-style)"
		echo "file:    $OMARCHY_VTRGB"
		echo "setvtrgb: $(command -v setvtrgb || echo missing)"
		if systemctl is-enabled vtrgb-omarchy-gruvbox.service >/dev/null 2>&1; then
			echo "boot:    system unit vtrgb-omarchy-gruvbox.service enabled"
		else
			echo "boot:    not installed (run: $0 --install-system-unit)"
		fi
		exit 0
		;;
	--install-system-unit | install-system-unit)
		disable_user_unit_if_present
		install_system_unit
		exit 0
		;;
	# legacy alias
	--install-systemd-unit | install-systemd-unit)
		disable_user_unit_if_present
		install_system_unit
		exit 0
		;;
	omarchy-gruvbox | gruvbox | omarchy | default | "")
		disable_user_unit_if_present
		apply_omarchy
		;;
	matugen)
		apply_matugen
		;;
	*)
		echo "Unknown option: $cmd" >&2
		usage
		exit 1
		;;
esac
