#!/usr/bin/env bash
# htop.sh — open htop in a floating terminal (clean env)
set -euo pipefail

CLASS="dotfiles-floating"

# Prefix to scrub noisy GTK env vars for this launch only
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

# Pick a terminal and run nmtui
if command -v kitty >/dev/null 2>&1; then
  exec "${CLEAN_ENV[@]}" kitty --class "$CLASS" -e htop
elif command -v ghostty >/dev/null 2>&1; then
  # ghostty prefers --command
  exec "${CLEAN_ENV[@]}" ghostty --class "$CLASS" --command htop
elif command -v alacritty >/dev/null 2>&1; then
  exec "${CLEAN_ENV[@]}" alacritty --class "$CLASS","$CLASS" -e htop
elif command -v footclient >/dev/null 2>&1; then
  exec "${CLEAN_ENV[@]}" footclient --app-id "$CLASS" htop
elif command -v wezterm >/dev/null 2>&1; then
  exec "${CLEAN_ENV[@]}" wezterm start --class "$CLASS" -- htop
elif command -v gnome-terminal >/dev/null 2>&1; then
  exec "${CLEAN_ENV[@]}" gnome-terminal -- htop
else
  exec "${CLEAN_ENV[@]}" xterm -e htop
fi
