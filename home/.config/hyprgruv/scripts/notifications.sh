#!/usr/bin/env bash
# Notification helpers — SwayNC only.

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
exec "$SCRIPTS/swaync.sh" "$@"