#!/bin/bash
# =============================================================================
# Centralized Font Configuration - Single Source of Truth
# =============================================================================
#
# This is THE ONLY FILE you should edit when changing fonts.
#
# Your three font roles (as defined by you):
#   • FONT_TEXT    → Terminals (Kitty) + browser text feel + notification bodies
#                    Currently: ShureTechMono Nerd Font
#
#   • FONT_UI      → App menus, Waybar, Rofi, GTK apps, most "normal" UI
#                    Currently: Agave Nerd Font Propo (excellent for menus)
#
#   • FONT_HEADER  → SDDM login screen, Hyprlock (big time/date + important labels),
#                    Wlogout power menu, rare decorative/emphasis headers
#                    Currently: HeavyData Nerd Font
#
# After you edit any of the three variables below, run:
#     ~/.config/settings/apply-fonts.sh
#
# This will push the changes to every config that needs them.
# =============================================================================

# --- THE THREE FONTS YOU CARE ABOUT ---
export FONT_TEXT="ShureTechMono Nerd Font"
export FONT_UI="Agave Nerd Font Propo"
export FONT_HEADER="HeavyData Nerd Font"

# --- READY-TO-USE STRINGS (with common sizes/weights) ---
# Tweak the numbers here if you want different default sizes per role.
export FONT_TEXT_FULL="$FONT_TEXT ${FONT_SIZE_TEXT:-12}"
export FONT_UI_FULL="$FONT_UI ${FONT_SIZE_UI:-12.5}"
export FONT_HEADER_FULL="$FONT_HEADER ${FONT_SIZE_HEADER:-Regular}"

# Individual size exports (easy to override per-role)
export FONT_SIZE_TEXT=12
export FONT_SIZE_UI=12.5
export FONT_SIZE_HEADER=13
# Waypaper GTK (toolbar = UI, search/tooltips = TEXT)
export FONT_SIZE_WAYPAPER_UI=11
export FONT_SIZE_WAYPAPER_TEXT=11
export FONT_SIZE_WAYPAPER_TOOLTIP=10
# Rofi launcher menus
export FONT_SIZE_LAUNCHER=16

# Family-only versions (no size) for tools that add their own size
export FONT_TEXT_FAMILY="$FONT_TEXT"
export FONT_UI_FAMILY="$FONT_UI"
export FONT_HEADER_FAMILY="$FONT_HEADER"

# --- SPECIAL VARIANTS (only change if you know what you're doing) ---
# Some tools like exact " Regular" or " Propo Regular" suffixes.
export FONT_UI_PROPO_REGULAR="Agave Nerd Font Propo Regular"
export FONT_HEADER_REGULAR="HeavyData Nerd Font Regular"

# =============================================================================
# Quick switch examples (uncomment one block, run apply-fonts.sh, enjoy)
# =============================================================================
# Example: Try a different text font for terminals
# export FONT_TEXT="JetBrainsMono Nerd Font"
# export FONT_TEXT_FULL="$FONT_TEXT 12"

# Example: Make UI (menus) use something more condensed
# export FONT_UI="Iosevka Nerd Font Propo"
# export FONT_UI_FULL="$FONT_UI 12"

# Example: Dramatic header font
# export FONT_HEADER="BigBlueTerm437 Nerd Font"
# export FONT_HEADER_FULL="$FONT_HEADER 14"
