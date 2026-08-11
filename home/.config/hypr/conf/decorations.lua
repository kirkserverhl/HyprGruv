local HOME = os.getenv("HOME") or ""
local settings = require("conf.settings")
local is_laptop = settings.is_laptop()

-- ---------------------------------------------------------------------------
-- Decorations by device profile (not Blitz)
--
--   Laptop  — conserve iGPU / battery: 1 blur pass, small size, light shadows,
--             no inactive transparency, no cinematic screen shader.
--   Desktop — richer blur/shadows when AC + dGPU is typical.
--
-- Blitz mode (hyprgruv-settings → Blitz) is work-focus: turns blur/anim/gaps
-- OFF at runtime via blitz-mode.sh; it is NOT a machine profile.
--
-- Runtime override: apply-hypr-blur.sh (state hypr-blur.conf / settings UI).
-- ---------------------------------------------------------------------------

local blur_passes = settings.read_number("blur_passes", is_laptop and 1 or 3)
local blur_size = settings.read_number("blur_size", is_laptop and 6 or 10)
local shadow_on = settings.read_bool("shadow_enabled", true)

local decorations = {
	rounding = is_laptop and 8 or 10,
	rounding_power = 2.0,

	-- Opacity on inactive windows costs extra compositing; keep full on laptop.
	active_opacity = 1.0,
	inactive_opacity = is_laptop and 1.0 or 0.95,
	fullscreen_opacity = 1.0,

	shadow = {
		enabled = shadow_on,
		range = is_laptop and 12 or 30,
		render_power = is_laptop and 2 or 3,
		color = 0x66000000,
	},

	blur = {
		enabled = true,
		size = blur_size,
		passes = blur_passes,
		ignore_opacity = false,
		contrast = is_laptop and 0.75 or 0.8,
		vibrancy = is_laptop and 0.15 or 0.2,
		xray = false,
		new_optimizations = true,
	},

	dim_inactive = false,
}

-- Full-screen post shader is GPU-heavy — desktop only when present.
if not is_laptop then
	local screen_shader = HOME .. "/.config/hypr/shaders/cinematic.frog"
	if io.open(screen_shader, "r") then
		decorations.screen_shader = screen_shader
	end
end

hl.config({ decoration = decorations })
