#!/usr/bin/env bash
# Step MX Mechanical onboard LED (HID++ Backlight2). Not the monitor.
# Needs hidraw uaccess (lib/udev/99-hyprgruv-logitech-hidpp.rules).
set -euo pipefail

iDIR="$HOME/.config/hyprgruv/icons/notifications"
SELF="$(readlink -f "$0")"
PY="${SELF%.sh}.py"

dir="${1:-}"
case "$dir" in
	--inc | up | +) dir=inc ;;
	--dec | down | -) dir=dec ;;
	*)
		echo "usage: $0 --inc|--dec" >&2
		exit 2
		;;
esac

notify_level() {
	local level="$1" max="$2" pct icon
	if [[ "$max" -le 0 ]]; then
		max=1
	fi
	pct=$((level * 100 / max))
	if [[ "$level" -le 0 ]]; then
		icon="$iDIR/brightness-20.png"
	elif [[ "$pct" -le 40 ]]; then
		icon="$iDIR/brightness-40.png"
	elif [[ "$pct" -le 70 ]]; then
		icon="$iDIR/brightness-60.png"
	else
		icon="$iDIR/brightness-100.png"
	fi
	notify-send -e \
		-h string:x-canonical-private-synchronous:osd \
		-u low \
		-i "$icon" \
		"Keyboard" "${level}/${max}"
}

out=""
if [[ -x "$PY" ]]; then
	out="$(python3 "$PY" "$dir" 2>/dev/null || true)"
fi

if [[ "$out" == ok* ]]; then
	# ok <level> <max>
	notify_level "$(awk '{print $2}' <<<"$out")" "$(awk '{print $3}' <<<"$out")"
	exit 0
fi

# hidraw not writable / HID++ failed — firmware may still handle the
# media-layer F3/F4 keys. Tell the user once per session if we own F3/F4.
notify-send -e \
	-h string:x-canonical-private-synchronous:osd \
	-u low \
	-i "$iDIR/brightness-20.png" \
	"Keyboard" "Onboard light needs hidraw access"
exit 1
