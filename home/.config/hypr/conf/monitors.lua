-- conf/monitors.lua
-- Desktop: multi-monitor layout (desc: matching).
-- Laptop: HyprLab work-dock profile (serial-matched). Runtime pinning lives in
-- apply-laptop-monitors.sh so hotplug cannot race and flip left/right.
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
	--
	-- Do not use position=auto on the built-in panel, and do not re-bind
	-- monitors from Lua events. eDP-1 enumerates first; auto parks it at 0x0
	-- and a get_monitors() race then "corrects" the laptop to 0x0 while the
	-- dock is still attaching — that flipped LG onto the right last time.
	hl.monitor({
		output = "desc:LG Electronics LG FULL HD 103MXTC4F409",
		mode = "1920x1080@60.00",
		position = "0x0",
		scale = 0.833333,
	})
	hl.monitor({
		output = "desc:LG Display 0x061F",
		mode = "1920x1080@60.02",
		position = "2307x281",
		scale = 1.2,
	})
end

-- Catch-all: any monitor not matched above (or unknown outputs).
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
