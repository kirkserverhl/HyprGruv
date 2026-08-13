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
	-- HyprGruv desk only (monitors_mode=desktop). HyprLab never loads this.
	-- Left → right: 24CN65 (vertical) | LG FULL HD | LG Monitor | TV
	-- Match on description — connector names move when cables are swapped.
	-- apply-desktop-monitors.sh re-pins this same geometry on login/hotplug.

	hl.monitor({
		output = "desc:LG Electronics 24CN65",
		mode = "1920x1080@60.00",
		position = "0x59",
		scale = 1.2,
		transform = 1, -- vertical / rotated 90°
	})

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

	-- LG TV (DP→HDMI): two profiles, same 1920x1080 logical size.
	--   monitor  1920x1080@120 scale 1  — desk / Super+Alt+M
	--   video    3840x2160@30  scale 2  — watching
	-- Never send 4096x2160 (DCI) — 16:9 TVs show side bars + vertical squash.
	-- Force SDR so the TV does not flip into a cinema picture mode.
	local tv_profile = settings.read("tv_mode", "monitor")
	local tv_res, tv_scale
	if tv_profile == "video" then
		tv_res, tv_scale = "3840x2160@30.00", 2
	else
		tv_res, tv_scale = "1920x1080@120.00", 1
	end
	hl.monitor({
		output = "desc:LG Electronics LG TV",
		mode = tv_res,
		position = "4102x0",
		scale = tv_scale,
		cm = "srgb",
		bitdepth = 8,
		supports_hdr = -1,
		supports_wide_color = -1,
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
		scale = 1.2,
	})
	hl.monitor({
		output = "desc:LG Display 0x061F",
		mode = "1920x1080@60.02",
		-- 1920/1.2 = 1600. Same scale/height as the dock, so y=0 and flush.
		position = "1600x0",
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
