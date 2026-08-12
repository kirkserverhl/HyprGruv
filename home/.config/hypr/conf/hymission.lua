-- conf/hymission.lua
-- hymission plugin config + Mission Control keybinds (Hyprland 0.55+ Lua API).
--
-- Plugin often loads AFTER first config pass (hyprpm-reload). apply_hymission() is
-- idempotent and re-run via reapply_hymission() from hyprpm-reload.sh.
--
-- Hot corners: launch-hotcorners.sh (bottom corners → mission-control.sh) — not a
-- separate hyprpm plugin.
--
-- Keybinds (do not steal these in keybinds.lua):
--   Alt+Tab / Alt+` / Alt+Down  → overview (all workspaces)
--   Alt+Shift+`                 → current workspace only
-- Super+Down is intentionally NOT bound here — keybinds.lua uses Super+arrows
-- for focus/resize/move navigation (same as Super+hjkl).
-- Window cycle is Super+Alt+Tab in keybinds.lua.

local function mission_control_toggle()
	if hl.plugin.hymission == nil then
		hl.exec_cmd(
			"notify-send -u low 'Mission Control' 'hymission not loaded — wait for login or: hyprpm reload'"
		)
		return
	end
	hl.plugin.hymission.toggle("forceall")
end

local function mission_control_current_workspace()
	if hl.plugin.hymission == nil then
		hl.exec_cmd(
			"notify-send -u low 'Mission Control' 'hymission not loaded — wait for login or: hyprpm reload'"
		)
		return
	end
	hl.plugin.hymission.toggle("onlycurrentworkspace")
end

local function apply_hymission()
	if hl.plugin.hymission == nil then
		return false
	end

	hl.config({
		plugin = {
			hymission = {
				layout_engine = "mission-control",
				expand_selected_window = true,
				overview_focus_follows_mouse = true,
				multi_workspace_sort_recent_first = true,
				workspace_change_keeps_overview = true,
			},
		},
	})
	return true
end

-- Called from hyprpm-reload after plugins load (global for hyprctl eval)
function reapply_hymission()
	return apply_hymission()
end

apply_hymission()

hl.on("hyprland.start", function()
	-- Plugin may still be loading; hyprpm-reload re-applies shortly after.
	apply_hymission()
end)

local mod = "ALT"

-- Mission Control: all monitors / all workspaces
-- (Super+Down left free for Super+arrow focus nav in keybinds.lua)
hl.bind(mod .. " + Tab", mission_control_toggle) -- #window #mission Mission Control (all)
hl.bind(mod .. " + grave", mission_control_toggle) -- #window #mission Mission Control (all)
hl.bind(mod .. " + down", mission_control_toggle) -- #window #mission Mission Control (all)

-- Current workspace only
hl.bind(mod .. " + SHIFT + grave", mission_control_current_workspace) -- #window #mission Mission Control (workspace)
