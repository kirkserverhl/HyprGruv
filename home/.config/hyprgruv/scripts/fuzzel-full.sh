#!/usr/bin/env bash
# Back-compat wrapper — full launcher is rofi now.
exec "$(dirname "${BASH_SOURCE[0]}")/rofi-full.sh" "$@"