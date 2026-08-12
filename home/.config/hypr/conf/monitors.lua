-- conf/monitors.lua
-- Desktop: multi-monitor layout (desc: matching).
-- Laptop: HyprLab work-dock profile when that panel is present; else built-in only.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Monitors/

local settings = require("conf.settings")
local mode = settings.read("monitors_mode", nil)
if not mode or mode == "" then
	mode = settings.is_laptop() and "laptop" or "desktop"
end

if mode == "desktop" then
	-- Vertical monitor (rotated) explicitly placed on the far left.
	hl.monitor({
		output = "desc:LG Electronics 24CN65",
		mode = "1920x1080@60.00",
		position = "0x59",
		scale = 1.2,
		transform = 1, -- vertical / rotated 90°
	})

	-- Horizontal monitors arranged left-to-right after the vertical one.
	hl.monitor({
		output = "desc:LG Electronics LG FULL HD",
		mode = "1920x1080@60.00",
		position = "900x59",
		scale = 1.2,
	})

	hl.monitor({
		output = "desc:LG Electronics LG Monitor",
		mode = "1920x1080@60.00",
		position = "2501x59",
		scale = 1.2,
	})

	hl.monitor({
		output = "desc:LG Electronics LG TV",
		mode = "1920x1080@60.00",
		position = "4102x0",
		scale = 1,
	})
elseif mode == "laptop" then
	-- HyprLab + work dock only. Serial-matched so the home desktop LG FULL HD
	-- (same model, different panel) never picks this up.
	local WORK_DOCK_SERIAL = "103MXTC4F409"
	local WORK_DOCK = "desc:LG Electronics LG FULL HD 103MXTC4F409"
	local LAPTOP_PANEL = "desc:LG Display 0x061F"

	local function work_dock_connected()
		local ok, mons = pcall(hl.get_monitors)
		if not ok or type(mons) ~= "table" then
			return false
		end
		for _, mon in ipairs(mons) do
			local serial = tostring(mon.serial or "")
			local desc = tostring(mon.description or "")
			if serial == WORK_DOCK_SERIAL or desc:find(WORK_DOCK_SERIAL, 1, true) then
				return true
			end
		end
		return false
	end

	local function apply_laptop_layout()
		if work_dock_connected() then
			-- Dock left (logical ~2304px at 0.833333), laptop to the right.
			hl.monitor({
				output = WORK_DOCK,
				mode = "1920x1080@60.00",
				position = "0x0",
				scale = 0.833333,
			})
			hl.monitor({
				output = LAPTOP_PANEL,
				mode = "1920x1080@60.02",
				position = "2307x281",
				scale = 1.2,
			})
		else
			hl.monitor({
				output = LAPTOP_PANEL,
				mode = "1920x1080@60.02",
				position = "0x0",
				scale = 1.2,
			})
		end
	end

	-- Parse-time rules: dock placement is exact; laptop sits auto-right until
	-- the hotplug hooks pin 2307x281 (or 0x0 when the dock is gone).
	hl.monitor({
		output = WORK_DOCK,
		mode = "1920x1080@60.00",
		position = "0x0",
		scale = 0.833333,
	})
	hl.monitor({
		output = LAPTOP_PANEL,
		mode = "1920x1080@60.02",
		position = "auto",
		scale = 1.2,
	})

	apply_laptop_layout()
	hl.on("hyprland.start", apply_laptop_layout)
	hl.on("monitor.added", apply_laptop_layout)
	hl.on("monitor.removed", apply_laptop_layout)
	hl.on("config.reloaded", apply_laptop_layout)
end

-- Catch-all: any monitor not matched above (or unknown outputs).
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
