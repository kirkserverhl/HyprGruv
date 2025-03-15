#!/bin/bash
# sddm-sugar-candy-install

# Define asset paths
ASSET_DIR="$HOME/.hyprgruv/assets/sddm"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOME/.hyprgruv/lib/common.sh"
source "$HOME/.hyprgruv/lib/state.sh"

# Move sddm.conf.d
move_dir "$ASSET_DIR/sddm.conf.d" "usr/lib/sddm"

# Move sddm.jpg
move_file "$ASSET_DIR/sugar-candy" "/usr/share/sddm/themes/"

# Completion message
echo "SDDM theme installation complete." | lsd-print
echo "You can test the theme using the command: sudo sddm --test-mode" | lsd-print
echo "To exit the test, press Ctrl+C." | lsd-print
echo ""
sleep 1
exit 0
