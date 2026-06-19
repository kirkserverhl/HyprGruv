#!/usr/bin/env bash
# Full fuzzel launcher — all installed apps
pkill -x fuzzel 2>/dev/null
exec fuzzel -n fuzzel "$@"