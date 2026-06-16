#!/bin/bash
# Delegates to the installer SSH key wizard (gum + header)
exec bash "${HYPRGRUV_DIR:-$HOME/.hyprgruv}/lib/scripts/ssh_key.sh" "$@"