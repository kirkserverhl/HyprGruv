-- conf/hymission.lua
-- hymission plugin config + Mission Control keybinds (Hyprland 0.55+ Lua API).

local function mission_control_toggle()
	if hl.plugin.hymission == nil then
		return
	end
	hl.plugin.hymission.toggle("forceall")
end

local function mission_control_current_workspace()
	if hl.plugin.hymission == nil then
		return
	end
	hl.plugin.hymission.toggle("onlycurrentworkspace")
end

local function apply_hymission()
	if hl.plugin.hymission == nil then
		return
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
end

apply_hymission()

hl.on("hyprland.start", function()
	os.execute("hyprpm reload >/dev/null 2>&1 || true")
	apply_hymission()
end)

local mod = "ALT"

-- Mission Control: all monitors / all workspaces
hl.bind(mod .. " + Tab", mission_control_toggle)
hl.bind(mod .. " + grave", mission_control_toggle)
hl.bind(mod .. " + down", mission_control_toggle)

-- Current workspace only
hl.bind(mod .. " + SHIFT + grave", mission_control_current_workspace)