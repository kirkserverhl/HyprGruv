#!/usr/bin/env bash
# Enable IdeaPad/Yoga Fn-lock so the F-row emits F1–F12 without holding Fn.
# HyprGruv does not assign F-keys distribution-wide — each keyboard map owns them.
# No-op when platform::fnlock is absent (desktop / non-Lenovo).
set -euo pipefail

if ! command -v brightnessctl >/dev/null 2>&1; then
	exit 0
fi

if ! brightnessctl -l 2>/dev/null | grep -q "Device 'platform::fnlock'"; then
	exit 0
fi

brightnessctl -q -d 'platform::fnlock' set 1
