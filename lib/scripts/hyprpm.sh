#!/usr/bin/env bash
# hyprpm.sh — fetch/build plugin sources, then load them into Hyprland
set -euo pipefail

if ! command -v hyprpm >/dev/null 2>&1; then
  echo "[hyprpm] hyprpm not found — skipping plugin setup"
  exit 0
fi

echo "[hyprpm] Updating plugin sources..."
hyprpm update

echo "[hyprpm] Reloading plugins..."
hyprpm reload