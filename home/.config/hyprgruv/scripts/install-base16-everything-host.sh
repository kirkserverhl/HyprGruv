#!/usr/bin/env bash
# install-base16-everything-host.sh — register native messaging for Chrome + Brave
#
# Extension ID (Chrome Web Store / Brave): jmofeafhkeohbpbedgbnkdlfaomjbnkf

set -euo pipefail

HOST_NAME="com.base16.everything"
EXTENSION_ID="${BASE16_EXTENSION_ID:-jmofeafhkeohbpbedgbnkdlfaomjbnkf}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_PY="$(cd "${SCRIPT_DIR}/../base16-everything" && pwd)/base16_config_host.py"

if [[ ! -f "$HOST_PY" ]]; then
    echo "Missing native host: $HOST_PY" >&2
    exit 1
fi

chmod +x "$HOST_PY"

MANIFEST_CONTENT=$(cat <<EOF
{
  "name": "$HOST_NAME",
  "description": "Native messaging host for Base16 Everything (matugen sync)",
  "path": "$HOST_PY",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
EOF
)

install_manifest() {
    local dir="$1"
    mkdir -p "$dir"
    printf '%s\n' "$MANIFEST_CONTENT" >"$dir/$HOST_NAME.json"
}

install_manifest "$HOME/.config/google-chrome/NativeMessagingHosts"
install_manifest "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
install_manifest "$HOME/.config/chromium/NativeMessagingHosts"

echo "Installed $HOST_NAME for extension $EXTENSION_ID"