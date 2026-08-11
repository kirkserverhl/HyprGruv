-- conf/monitors.lua
-- Desktop: multi-monitor layout (desc: matching).
-- Laptop / unknown: preferred + auto only (see settings/monitors_mode.sh).
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
end

-- Catch-all: any monitor not matched above (or full laptop profile).
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
