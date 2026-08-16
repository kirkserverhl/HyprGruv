-- conf/autostart.lua
-- Converted from conf/autostart.conf
-- Most exec-once become hl.on("hyprland.start", function() hl.exec_cmd(...) end)

local SCRIPTS = require("conf.scripts_path").get()
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
	-- Brief delay so HYPRLAND_INSTANCE_SIGNATURE + socket are fully ready.
	-- Script waits/polls further; on outdated headers it runs hyprpm update then reload.
	hl.exec_cmd("sleep 0.5 && " .. HYPRPM_RELOAD)
end

local function start_systemd_session()
	-- Copy compositor + toolkit env into systemd user services / portals.
	-- Explicit list (not --all) so SSH/TTY leftovers stay out.
	-- Omit NVIDIA/WLR leftovers (__GLX_*, WLR_*, GBM_*).
	local session_env = table.concat({
		"WAYLAND_DISPLAY",
		"XDG_CURRENT_DESKTOP",
		"XDG_SESSION_TYPE",
		"XDG_SESSION_DESKTOP",
		"GDK_BACKEND",
		"QT_QPA_PLATFORM",
		"QT_QPA_PLATFORMTHEME",
		"QT_WAYLAND_DISABLE_WINDOWDECORATION",
		"SDL_VIDEODRIVER",
		"CLUTTER_BACKEND",
		"LIBVA_DRIVER_NAME",
		"ELECTRON_OZONE_PLATFORM_HINT",
		"MOZ_ENABLE_WAYLAND",
		"XDG_MENU_PREFIX",
		"GROK_APPEARANCE",
		"LC_GROK_APPEARANCE",
	}, " ")
	hl.exec_cmd("dbus-update-activation-environment --systemd " .. session_env)
	hl.exec_cmd("systemctl --user import-environment " .. session_env)
	hl.exec_cmd("systemctl --user start hyprland-session.target")
end

-- Hyprpm: session start only. Do NOT hook config.reloaded — plugin unload reloads
-- config and previously re-triggered hyprpm + apply-bar-mode in an infinite loop.
hl.on("hyprland.start", reload_hyprpm)

-- Run on every Hyprland start (use hl.on for the event)
hl.on("hyprland.start", function()
	-- systemd graphical session (portal, polkit units, XDG autostart)
	start_systemd_session()

	-- Polkit: hyprpolkitagent only. launch script stops KDE/GNOME leftovers
	-- (plasma-desktop pulls in polkit-kde-agent; two agents = two dialog styles).
	start_polkit_agent()

	-- Idle + bar (exclusive: waybar | hyprbars | off — Alt+W cycles, state persists)
	-- Early waybar for snappy login when last mode was waybar; hyprpm-reload.sh
	-- re-enforces the saved mode after plugins load (hyprpm always loads hyprbars
	-- when enabled, so the final apply-bar-mode pass is what prevents both bars).
	-- Prefer machine-local hypridle from apply-machine-profile.sh when present.
	hl.exec_cmd(
		'sh -c \'hidle=${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/hypridle.conf; if [ -f "$hidle" ]; then hypridle -c "$hidle" &; else hypridle &; fi; st=${XDG_STATE_HOME:-$HOME/.local/state}/waybar; m=$(tr -d "[:space:]" <"$st/bar_mode" 2>/dev/null); if [ "$m" = "waybar" ] || [ -z "$m" ]; then ~/.config/waybar/scripts/launch.sh; fi; sleep 0.6; ' .. SCRIPTS .. '/sync-bar-mode.sh\''
	)

	-- Clipboard history: text and screenshots live in separate cliphist DBs
	-- so screenshot spam never evicts copied text.
	hl.exec_cmd('wl-paste --type text --watch cliphist -db-path "$HOME/.cache/cliphist/text.db" store')
	hl.exec_cmd('wl-paste --type image --watch cliphist -db-path "$HOME/.cache/cliphist/db" store')

	-- Restart wallpaper daemons, then restore canonical default_wp.png on login.
	hl.exec_cmd("killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true")
	hl.exec_cmd("sleep 0.5 && awww-daemon &")
	hl.exec_cmd("waypaper-engine daemon &")
	-- No waypaper post_command on login — palette/matugen only when switching wallpapers.
	hl.exec_cmd(SCRIPTS .. "/restore_wallpaper.sh &")

	-- GTK / icons / cursor for active colorscheme (default: gruvbox + Bibata Gruvbox)
	hl.exec_cmd(SCRIPTS .. "/apply-desktop-assets.sh")

	-- Workspace monitor setup script (also re-pins HyprLab dock on hotplug).
	hl.exec_cmd(SCRIPTS .. "/monitor-workspaces.sh")

	-- HyprLab work-dock layout (no-op on desktop). Delayed so hyprctl sees DP-*.
	hl.exec_cmd("sleep 2 && " .. SCRIPTS .. "/apply-laptop-monitors.sh")

	-- IdeaPad/Yoga: F-row = F1–F12 without holding Fn (no-op on other machines).
	-- F-keys are not assigned distribution-wide; per-keyboard maps own them.
	hl.exec_cmd(SCRIPTS .. "/fn-lock.sh")

	-- First-login welcome: background package sync + HyprGruv Settings (opt-out via menu checkbox).
	-- Manual re-run: bash ~/.config/hyprgruv/scripts/hyprgruv-welcome.sh
	-- Re-enable after opt-out: rm ~/.local/state/hyprgruv-settings/welcome-disabled
	hl.exec_cmd("sleep 5 && " .. SCRIPTS .. "/hyprgruv-welcome.sh &")

	-- Post-install wizard runs from install.sh (before reboot).
	-- Manual re-run: FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

	-- Role-aware login sync (both machines):
	--   deploy → rofi hyprgruv pull when behind + notify on followed repos
	--   source → notify when dirty repos need git-eod
	-- Also enables git-eod-remind.timer / hyprgruv-update-check.timer as backups.
	hl.exec_cmd("sleep 40 && ~/.hyprgruv/lib/scripts/login-sync-prompt.sh &")

	-- Auto-mount
	hl.exec_cmd("udiskie")

	-- GPU Screen Recorder overlay (Alt+Z). Unit is a no-op until the package is installed.
	hl.exec_cmd("systemctl --user start gpu-screen-recorder-ui.service")

	-- Notification daemon (SwayNC)
	hl.exec_cmd(SCRIPTS .. "/notify-autostart.sh")

	-- Saved blur profile (overrides decorations.lua defaults after load)
	hl.exec_cmd(SCRIPTS .. "/apply-hypr-blur.sh")

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
	hl.exec_cmd(SCRIPTS .. "/apply-hypr-blur.sh")
	hl.exec_cmd(SCRIPTS .. "/apply-laptop-monitors.sh")
end)

-- Hotplug pin. Script-only — do not query hl.get_monitors() here
-- (that race parked the laptop at 0x0 and stacked the cursors).
hl.on("monitor.added", function()
	hl.exec_cmd("sleep 1.2 && " .. SCRIPTS .. "/apply-laptop-monitors.sh")
end)
hl.on("monitor.removed", function()
	hl.exec_cmd("sleep 0.8 && " .. SCRIPTS .. "/apply-laptop-monitors.sh")
end)

-- One-time things that were plain "exec" (not exec-once) in original main file
-- moved to main hyprland.lua