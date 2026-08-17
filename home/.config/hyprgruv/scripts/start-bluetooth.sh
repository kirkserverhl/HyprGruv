#!/usr/bin/env bash
# Bring up the system Bluetooth stack for a Hyprland session.
# Radio is often soft-blocked on this IdeaPad until something unblocks it.
set -u

rfkill unblock bluetooth >/dev/null 2>&1 || true

if ! systemctl is-active --quiet bluetooth; then
	systemctl start bluetooth >/dev/null 2>&1 || true
fi

# bluetoothd can take a moment after the unit reports active.
for _ in $(seq 1 20); do
	if bluetoothctl --timeout 1 show >/dev/null 2>&1; then
		break
	fi
	sleep 0.25
done

bluetoothctl --timeout 3 power on >/dev/null 2>&1 || true
bluetoothctl --timeout 2 pairable on >/dev/null 2>&1 || true

# Reconnect anything already paired (keyboards, mice, etc.).
while read -r _ mac _; do
	[[ -n "${mac:-}" ]] || continue
	bluetoothctl --timeout 8 connect "$mac" >/dev/null 2>&1 || true
done < <(bluetoothctl --timeout 3 devices Paired 2>/dev/null)

exit 0
