#!/usr/bin/env bash
# reset_install_state.sh — clear local install progress (does not touch system packages)
set -euo pipefail

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
ASSET_DIR="$HYPR_DIR/assets"

rm -f "$ASSET_DIR/install_state.json" "$ASSET_DIR/completed_steps.txt" "$ASSET_DIR/user_choices.txt"

echo "Install state cleared in $ASSET_DIR"
echo "Next full install:  cd $HYPR_DIR && ./install.sh"
echo "Force re-run steps:   FORCE=1 ./install.sh"
echo "Reset + force:        RESET_STATE=1 FORCE=1 ./install.sh"