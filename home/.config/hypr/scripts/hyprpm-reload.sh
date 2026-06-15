#!/usr/bin/env bash
# hyprpm-reload.sh — load hyprpm plugins on each Hyprland session / config reload
if ! command -v hyprpm >/dev/null 2>&1; then
  exit 0
fi
hyprpm reload >/dev/null 2>&1 || true