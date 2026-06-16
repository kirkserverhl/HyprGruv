-- conf/autostart.lua
-- Converted from conf/autostart.conf
-- Most exec-once become hl.on("hyprland.start", function() hl.exec_cmd(...) end)

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local HYPRPM_RELOAD = SCRIPTS .. "/hyprpm-reload.sh"

local function reload_hyprpm()
	hl.exec_cmd(HYPRPM_RELOAD)
end

-- Hyprpm: every new Hyprland session (login) and after config reload
hl.on("hyprland.start", reload_hyprpm)
hl.on("config.reloaded", reload_hyprpm)

-- Run on every Hyprland start (use hl.on for the event)
hl.on("hyprland.start", function()
	-- Polkit
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

	-- Idle + bar (or nothingless if that was the last choice via the toggle)
	hl.exec_cmd(
		'hypridle & sh -c \'s=${XDG_STATE_HOME:-$HOME/.local/state}/waybar/last_layout; if [ "$(cat "$s" 2>/dev/null)" = nothingless ]; then nothingless &; else ~/.config/waybar/scripts/launch.sh; fi\''
	)

	-- Clipboard history (images)
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Cleanup
	hl.exec_cmd(SCRIPTS .. "/cleanup.sh")

	-- Restart wallpaper system cleanly on every start
	hl.exec_cmd("killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true")
	hl.exec_cmd("waypaper-engine daemon &")

	-- Restore last wallpaper + re-apply matugen/colors on every login/start.
	-- Uses our script so we get both the image *and* the full post-processing (matugen etc.)
	-- with auto matugen (Dark Standard + source color 1); palette.sh is manual only (Ctrl+P).
	hl.exec_cmd("sleep 1.5 && ~/.config/hypr/scripts/restore_wallpaper.sh &")

	-- Cursor theme
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic-Gruvbox 24")

	-- Workspace monitor setup script
	hl.exec_cmd(SCRIPTS .. "/monitor-workspaces.sh")

	-- Post-install wizard runs from install.sh (before reboot). No auto kitty popup on login.
	-- Manual re-run: FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

	-- Auto-mount
	hl.exec_cmd("udiskie")

	-- Dunst
	hl.exec_cmd("dunst")

	-- cava-bg: Wayland-native audio visualizer as desktop background (dynamic colors from wallpaper)
	-- hl.exec_cmd("cava-bg on")

	-- The original also had a non-once exec here:
	-- hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- HyprSunset
hl.exec_cmd("hyprsunset --temperature 9000")

-- Non-once (run on every reload) items from original
hl.on("config.reloaded", function()
	hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- One-time things that were plain "exec" (not exec-once) in original main file
-- moved to main hyprland.lua
