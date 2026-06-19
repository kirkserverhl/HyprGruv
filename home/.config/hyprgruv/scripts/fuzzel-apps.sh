#!/usr/bin/env bash
# Back-compat wrapper — favorites launcher is rofi now.
exec "$(dirname "${BASH_SOURCE[0]}")/rofi-apps.sh" "$@"