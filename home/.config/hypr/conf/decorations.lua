local HOME = os.getenv("HOME") or ""
local settings = require("conf.settings")
local is_laptop = settings.is_laptop()

-- Defaults: desktop can run heavier blur; laptop profile softens for iGPU/battery.
-- Runtime override: apply-hypr-blur.sh (prefers state hypr-blur.conf when present).
local blur_passes = settings.read_number("blur_passes", is_laptop and 2 or 6)
local blur_size = settings.read_number("blur_size", is_laptop and 8 or 10)
local shadow_on = settings.read_bool("shadow_enabled", true)

local decorations = {
	rounding = 10,
	rounding_power = 2.0,

	active_opacity = 1.0,
	inactive_opacity = 0.95,
	fullscreen_opacity = 1.0,

	shadow = {
		enabled = shadow_on,
		range = is_laptop and 20 or 30,
		render_power = 3,
		color = 0x66000000,
	},

	blur = {
		enabled = true,
		size = blur_size,
		passes = blur_passes,
		ignore_opacity = false,
		contrast = 0.8,
		vibrancy = 0.2,
		xray = false,
		new_optimizations = true,
	},

	dim_inactive = false,
}

local screen_shader = HOME .. "/.config/hypr/shaders/cinematic.frog"
if io.open(screen_shader, "r") then
	decorations.screen_shader = screen_shader
end

hl.config({ decoration = decorations })
