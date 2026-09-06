-- conf/dynamite.lua
-- Trial keybinds for Sane's Dynamite Quickshell shell.
-- Super+Alt chords on purpose: they do not steal hyprgruv Super+Space / lock / volume.
-- Disable: comment out `require("conf.dynamite")` in hyprland.lua, then `hyprctl reload`.
-- Leave the session: `qs kill` then `~/.config/waybar/scripts/launch.sh`

local function qs_ipc(target, action)
	return hl.dsp.exec_cmd("qs ipc call " .. target .. " " .. (action or "toggle"))
end

-- #quickshell Dynamite launcher (island morph)
hl.bind("SUPER + ALT + SPACE", hl.dsp.global("quickshell:launcher"))
-- #quickshell Dynamite control center
hl.bind("SUPER + ALT + A", qs_ipc("controlcenter", "toggle"))
-- #quickshell Dynamite theme switcher
hl.bind("SUPER + ALT + T", hl.dsp.global("quickshell:theme"))
-- #quickshell Dynamite wallpaper picker
hl.bind("SUPER + ALT + SHIFT + T", hl.dsp.global("quickshell:wallpaper"))
-- #quickshell Dynamite settings
hl.bind("SUPER + ALT + comma", hl.dsp.global("quickshell:settings"))
-- #quickshell Dynamite calendar
hl.bind("SUPER + ALT + C", hl.dsp.global("quickshell:calendar"))
