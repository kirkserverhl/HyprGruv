#!/bin/bash
#
# launch-updates.sh
# Opens a floating terminal to perform system update (pacman/AUR) and keeps it open.

set -euo pipefail

# Use kitty (per terminal.sh) with the class that has a windowrule
exec kitty --class=hypr-updates -e bash -c '
  echo "==> Updating system (yay/paru/pacman)..."
  yay -Syu || paru -Syu || sudo pacman -Syu || true
  echo
  read -n 1 -s -r -p "Update complete. Press any key to close..."
'