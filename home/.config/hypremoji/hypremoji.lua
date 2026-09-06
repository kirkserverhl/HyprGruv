-- HyprEmoji Configuration

-- Keybind to open hypremoji
hl.bind("SUPER + period", hl.dsp.exec_cmd("hypremoji"))

-- Window rules live in ~/.config/hypr/conf/windowrules.lua
-- (centered 640×520, calculator height; GTK will not go narrower).
-- Do not duplicate them here — this file is not loaded by hyprland.lua.