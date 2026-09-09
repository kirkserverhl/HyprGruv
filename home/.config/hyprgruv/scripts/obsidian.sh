#!/usr/bin/env bash
# obsidian.sh — launch Obsidian with the HyprGruv default browser (Brave)
#   obsidian.sh           open the last vault
#   obsidian.sh new       create and open a new note (obsidian://new)
#   obsidian.sh <args>    passed through to /usr/bin/obsidian
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export BROWSER="$("$SCRIPT_DIR/read-setting.sh" browser brave)"
export PATH="${HOME}/.local/bin:${PATH}"

if [[ "${1:-}" == "new" ]]; then
	exec /usr/bin/obsidian "obsidian://new"
fi

exec /usr/bin/obsidian "$@"