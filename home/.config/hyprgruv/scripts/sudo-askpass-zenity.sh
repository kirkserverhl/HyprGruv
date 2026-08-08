#!/usr/bin/env bash
# Graphical sudo askpass for non-interactive Hyprland autostart (hyprpm update).
# Used when SUDO_ASKPASS points here and sudo needs a password without a TTY.
exec zenity --password --title="${SUDO_ASKPASS_TITLE:-Hyprland plugins (hyprpm)}" --timeout=120 2>/dev/null
