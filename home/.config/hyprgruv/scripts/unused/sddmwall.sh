#!/bin/bash
# ===================================================================
# sddmwall.sh — Legacy helper for the old "corners" SDDM theme
#
# NOTE: You are currently using sugar-candy (see /etc/sddm.conf.d/10-theme.conf).
# This script is kept for reference during the overhaul but is no longer called
# by the main wallpaper pipeline.
#
# If you decide to switch back to (or test) the corners theme, you can revive it.
# ===================================================================

sddmback="/usr/share/sddm/themes/corners/backgrounds/bg.png"
sddmconf="/usr/share/sddm/themes/corners/theme.conf"
slnkwall="${XDG_CONFIG_HOME:-$HOME/.config}/swww/wall.set"

if [ "$(getfacl -p /home/${USER} | grep user:sddm | awk '{print substr($0,length)}')" != "x" ]; then
    echo "granting sddm execution access to /home/${USER}..."
    setfacl -m u:sddm:x /home/${USER}
fi

if [ "$(grep "Background=" "${sddmconf}")" == "Background=\"${slnkwall}\"" ]; then
    echo "setting static sddm background..."
    sed -i "/^Background=/c\Background=\"${sddmback}\"" "${sddmconf}"
else
    echo "setting dynamic sddm background..."
    sed -i "/^Background=/c\Background=\"${slnkwall}\"" "${sddmconf}"
fi
