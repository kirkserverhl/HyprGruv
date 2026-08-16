#!/bin/bash
# =============================================================================
# Waybar / Hyprbars size profiles — laptop vs desktop
# =============================================================================
#
# Tune the LAPTOP_* values on HyprLab. Desktop numbers match the current
# 32" LG baseline and should stay put unless you want the desk bar smaller too.
#
# Heights are logical pixels (Waybar JSON + hyprbars). Font sizes are CSS px
# (same as today — pt does not track real monitor inches on Wayland).
#
# Apply:
#   ~/.config/waybar/scripts/apply-bar-size-profile.sh
#   ~/.config/waybar/scripts/launch.sh          # also applies, then restarts Waybar
#   hyprctl reload                              # picks up hyprbars bar_height
#
# Machine is ~/.config/settings/machine.sh (laptop|desktop), same as the rest
# of the profile split. Override for a dry run:
#   BAR_SIZE_MACHINE=laptop ~/.config/waybar/scripts/apply-bar-size-profile.sh
# =============================================================================

# --- Desktop (32" LG baseline — current) ---
DESKTOP_BAR_HEIGHT=32
DESKTOP_BAR_MARGIN_TOP=5
DESKTOP_BAR_MARGIN_X=14
DESKTOP_FONT_SIZE=16
DESKTOP_FONT_SIZE_EMPHASIS=18
DESKTOP_FONT_SIZE_CENTER=20
DESKTOP_HYPRBARS_TEXT=14
DESKTOP_MODULE_MIN_HEIGHT=28

# --- Laptop (placeholders — fine-tune on HyprLab) ---
# Starting guess: ~75% of desktop so 18px freshstart → 14, 32px bar → 24.
# Theme-specific heights (freshstart 36, gruv 42, …) shrink by the same
# delta (DESKTOP_BAR_HEIGHT - LAPTOP_BAR_HEIGHT) so proportions stay related.
LAPTOP_BAR_HEIGHT=24
LAPTOP_BAR_MARGIN_TOP=4
LAPTOP_BAR_MARGIN_X=10
LAPTOP_FONT_SIZE=12
LAPTOP_FONT_SIZE_EMPHASIS=14
LAPTOP_FONT_SIZE_CENTER=15
LAPTOP_HYPRBARS_TEXT=11
LAPTOP_MODULE_MIN_HEIGHT=20
