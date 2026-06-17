-- conf/autostart.lua
-- Converted from conf/autostart.conf
-- Most exec-once become hl.on("hyprland.start", function() hl.exec_cmd(...) end)

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local HYPRPM_RELOAD = SCRIPTS .. "/hyprpm-reload.sh"
local HOTCORNERS = SCRIPTS .. "/launch-hotcorners.sh"
local POLKIT_AGENT = SCRIPTS .. "/launch-hyprpolkitagent.sh"

local function start_polkit_agent()
	hl.exec_cmd(POLKIT_AGENT)
end

local function start_hotcorners()
	hl.exec_cmd(HOTCORNERS)
end

local function reload_hyprpm()
	hl.exec_cmd(HYPRPM_RELOAD)
end

local function start_systemd_session()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
	hl.exec_cmd("systemctl --user start hyprland-session.target")
end

-- Hyprpm: session start only. Do NOT hook config.reloaded — plugin unload reloads
-- config and previously re-triggered hyprpm + apply-bar-mode in an infinite loop.
hl.on("hyprland.start", reload_hyprpm)

-- Run on every Hyprland start (use hl.on for the event)
hl.on("hyprland.start", function()
	-- systemd graphical session (portal, polkit units, XDG autostart)
	start_systemd_session()

	-- Polkit (Hyprland-native agent; single instance via launch script)
	start_polkit_agent()

	-- Idle + bar (or nothingless if that was the last choice via the toggle)
	hl.exec_cmd(
		'hypridle & sh -c \'st=${XDG_STATE_HOME:-$HOME/.local/state}/waybar; if [ "$(cat "$st/last_layout" 2>/dev/null)" = nothingless ]; then nothingless &; elif [ "$(cat "$st/bar_mode" 2>/dev/null)" != hyprbars ]; then ~/.config/waybar/scripts/launch.sh; fi; sleep 0.6; ~/.config/hypr/scripts/sync-bar-mode.sh\''
	)

	-- Clipboard history (images)
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Cleanup
	hl.exec_cmd(SCRIPTS .. "/cleanup.sh")

	-- Restart wallpaper daemons, then restore canonical default_wp.png on login.
	hl.exec_cmd("killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true")
	hl.exec_cmd("sleep 0.5 && awww-daemon &")
	hl.exec_cmd("waypaper-engine daemon &")
	-- No waypaper post_command on login — palette/matugen only when switching wallpapers.
	hl.exec_cmd("~/.config/hypr/scripts/restore_wallpaper.sh &")

	-- Cursor theme
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic-Gruvbox 24")

	-- Workspace monitor setup script
	hl.exec_cmd(SCRIPTS .. "/monitor-workspaces.sh")

	-- Post-install wizard runs from install.sh (before reboot). No auto kitty popup on login.
	-- Manual re-run: FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

	-- Hyprgruv deploy target (laptop): touch ~/.config/hyprgruv/deploy-target
	-- Then: systemctl --user enable --now hyprgruv-update-check.timer
	hl.exec_cmd("sleep 90 && ~/.hyprgruv/lib/scripts/repo-update-check.sh --prompt-if-needed &")

	-- Auto-mount
	hl.exec_cmd("udiskie")

	-- Dunst
	hl.exec_cmd("dunst")

	-- Bottom-corner hot zones → hymission Mission Control
	start_hotcorners()

	-- cava-bg: Wayland-native audio visualizer as desktop background (dynamic colors from wallpaper)
	-- hl.exec_cmd("cava-bg on")

	-- The original also had a non-once exec here:
	-- hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

hl.on("hyprland.shutdown", function()
	os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)

-- HyprSunset
hl.exec_cmd("hyprsunset --temperature 9000")

-- Non-once (run on every reload) items from original
hl.on("config.reloaded", function()
	hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- One-time things that were plain "exec" (not exec-once) in original main file
-- moved to main hyprland.lua