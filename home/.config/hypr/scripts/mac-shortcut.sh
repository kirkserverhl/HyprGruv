#!/bin/bash
# Reliable macOS-style (SUPER/Cmd) → Ctrl+letter translation for Wayland.
# Uses wtype because Hyprland's sendshortcut can leave keys "stuck" (especially
# when repeating was involved or with Insert hacks).
#
# Usage:
#   mac-shortcut.sh copy     # Ctrl+C
#   mac-shortcut.sh paste    # Ctrl+V
#   mac-shortcut.sh cut      # Ctrl+X
#   mac-shortcut.sh undo     # Ctrl+Z
#   etc.

set -euo pipefail

action="${1:-}"

case "$action" in
    copy|c)
        wtype -M ctrl -k c -m ctrl
        ;;
    paste|v)
        wtype -M ctrl -k v -m ctrl
        ;;
    cut|x)
        wtype -M ctrl -k x -m ctrl
        ;;
    undo|z)
        wtype -M ctrl -k z -m ctrl
        ;;
    # Add more as needed. These were in the original mac section.
    i)
        wtype -M ctrl -k i -m ctrl
        ;;
    u)
        wtype -M ctrl -k u -m ctrl
        ;;
    k)
        wtype -M ctrl -k k -m ctrl
        ;;
    *)
        echo "Unknown mac-shortcut action: $action" >&2
        echo "Known: copy|c, paste|v, cut|x, undo|z, i, u, k" >&2
        exit 1
        ;;
esac
