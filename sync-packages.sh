#!/usr/bin/env bash
# Convenience wrapper — see lib/scripts/sync-packages.sh
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/scripts/sync-packages.sh" "$@"