#!/bin/bash
# Volume / mic OSD. Uses pactl (PipeWire Pulse). pamixer is not installed.
#
# Keys must change the sink you HEAR. Chrome (and other apps) often stay on
# the analog Line out via stream-restore while the configured default is the
# DisplayLink dock — adjusting @DEFAULT_SINK@ then only moves a silent device.
iDIR="$HOME/.config/hyprgruv/icons/notifications"
VOL_MAX=150
VOL_STEP=5

# ---------- target sink (playing stream, else default) ----------
target_sinks() {
	local sinks
	sinks="$(pactl list short sink-inputs 2>/dev/null | awk '$2 ~ /^[0-9]+$/ { print $2 }' | sort -u)"
	if [[ -n "$sinks" ]]; then
		printf '%s\n' "$sinks"
		return
	fi
	pactl get-default-sink
}

primary_sink() { target_sinks | head -n1; }

vol_num() {
	local sink="${1:-$(primary_sink)}"
	pactl get-sink-volume "$sink" 2>/dev/null | awk 'NR == 1 {
		for (i = 1; i <= NF; i++) {
			if ($i ~ /%$/) { gsub(/%/, "", $i); print int($i); exit }
		}
	}'
}

is_muted() {
	local sink="${1:-$(primary_sink)}"
	pactl get-sink-mute "$sink" 2>/dev/null | grep -q yes
}

get_volume_num() { vol_num "$(primary_sink)"; }

get_volume_label() {
	if is_muted; then
		printf "Muted"
	else
		printf "%s%%" "$(get_volume_num)"
	fi
}

get_icon() {
	if is_muted; then
		echo "$iDIR/volume-mute.png"
	else
		v="$(get_volume_num)"
		v="${v:-0}"
		if ((v <= 30)); then echo "$iDIR/volume-low.png"
		elif ((v <= 60)); then echo "$iDIR/volume-mid.png"
		else echo "$iDIR/volume-high.png"
		fi
	fi
}

notify_user() {
	local val label
	if is_muted; then
		val=0
	else
		val="$(get_volume_num)"
		val="${val:-0}"
	fi
	label="$(get_volume_label)"
	notify-send -e \
		-h int:value:"$val" \
		-h string:x-canonical-private-synchronous:osd \
		-u low \
		-i "$(get_icon)" \
		"Volume" "$label"
}

set_sink_percent() {
	local sink="$1" pct="$2"
	((pct < 0)) && pct=0
	((pct > VOL_MAX)) && pct=$VOL_MAX
	pactl set-sink-volume "$sink" "${pct}%"
}

nudge_sinks() {
	local delta="$1" sink cur new
	while IFS= read -r sink; do
		[[ -n "$sink" ]] || continue
		cur="$(vol_num "$sink")"
		cur="${cur:-0}"
		new=$((cur + delta))
		set_sink_percent "$sink" "$new"
	done < <(target_sinks)
}

inc_volume() {
	if is_muted; then
		toggle_mute
	else
		nudge_sinks "$VOL_STEP"
		notify_user
	fi
}

dec_volume() {
	if is_muted; then
		toggle_mute
	else
		nudge_sinks "-$VOL_STEP"
		notify_user
	fi
}

toggle_mute() {
	local sink
	if is_muted; then
		while IFS= read -r sink; do
			[[ -n "$sink" ]] || continue
			pactl set-sink-mute "$sink" 0
		done < <(target_sinks)
	else
		while IFS= read -r sink; do
			[[ -n "$sink" ]] || continue
			pactl set-sink-mute "$sink" 1
		done < <(target_sinks)
	fi
	notify_user
}

# ---------- Microphone ----------
is_mic_muted() { pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q yes; }

get_mic_num() {
	pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | awk 'NR == 1 {
		for (i = 1; i <= NF; i++) {
			if ($i ~ /%$/) { gsub(/%/, "", $i); print int($i); exit }
		}
	}'
}

get_mic_label() {
	if is_mic_muted; then
		printf "Muted"
	else
		printf "%s%%" "$(get_mic_num)"
	fi
}

get_mic_icon() {
	if is_mic_muted; then
		echo "$iDIR/microphone-mute.png"
	else
		echo "$iDIR/microphone.png"
	fi
}

notify_mic_user() {
	local val label
	if is_mic_muted; then
		val=0
	else
		val="$(get_mic_num)"
		val="${val:-0}"
	fi
	label="$(get_mic_label)"
	notify-send -e \
		-h int:value:"$val" \
		-h string:x-canonical-private-synchronous:mic_notif \
		-u low \
		-i "$(get_mic_icon)" \
		"Microphone" "$label"
}

# Default-source mute is not enough for RingCentral: it often has its own
# PipeWire source-output and keeps capturing. Flip the default source, then
# push the same mute state onto every capture stream (RC is the only mic app).
set_capture_streams_mute() {
	local flag="$1" # 1 = mute, 0 = unmute
	local idx
	while IFS=$'\t' read -r idx _; do
		[[ -n "$idx" ]] || continue
		pactl set-source-output-mute "$idx" "$flag" >/dev/null 2>&1 || true
	done < <(pactl list short source-outputs 2>/dev/null)
}

toggle_mic() {
	local flag
	if is_mic_muted; then
		pactl set-source-mute @DEFAULT_SOURCE@ 0
		flag=0
	else
		pactl set-source-mute @DEFAULT_SOURCE@ 1
		flag=1
	fi
	set_capture_streams_mute "$flag"
	notify_mic_user
}

nudge_mic() {
	local delta="$1" cur new
	if is_mic_muted; then
		toggle_mic
		return
	fi
	cur="$(get_mic_num)"
	cur="${cur:-0}"
	new=$((cur + delta))
	((new < 0)) && new=0
	((new > VOL_MAX)) && new=$VOL_MAX
	pactl set-source-volume @DEFAULT_SOURCE@ "${new}%"
	notify_mic_user
}

inc_mic_volume() { nudge_mic "$VOL_STEP"; }
dec_mic_volume() { nudge_mic "-$VOL_STEP"; }

# ---------- CLI ----------
case "$1" in
	--get)             get_volume_label ;;
	--inc)             inc_volume ;;
	--dec)             dec_volume ;;
	--toggle)          toggle_mute ;;
	--toggle-mic)      toggle_mic ;;
	--get-icon)        get_icon ;;
	--get-mic-icon)    get_mic_icon ;;
	--mic-inc)         inc_mic_volume ;;
	--mic-dec)         dec_mic_volume ;;
	*)                 get_volume_label ;;
esac
