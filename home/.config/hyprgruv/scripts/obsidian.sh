#!/usr/bin/env bash
# obsidian.sh — launch Obsidian with the HyprGruv default browser (Brave)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export BROWSER="$("$SCRIPT_DIR/read-setting.sh" browser brave)"
export PATH="${HOME}/.local/bin:${PATH}"

exec /usr/bin/obsidian "$@"