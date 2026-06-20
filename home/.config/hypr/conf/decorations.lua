local HOME = os.getenv("HOME") or ""

local decorations = {
	-- Active preset was rounding-more-blur (10px, not 25)
	rounding = 10,
	rounding_power = 2.0,

	active_opacity = 1.0,
	inactive_opacity = 0.95,
	fullscreen_opacity = 1.0,

	shadow = {
		enabled = true,
		range = 30,
		render_power = 3,
		-- Neutral shadow — 0x80900a0a had a red tint that haloed every window
		color = 0x66000000,
	},

	blur = {
		enabled = true,
		size = 10,
		passes = 6,
		ignore_opacity = false,
		contrast = 0.8,
		vibrancy = 0.2,
		xray = false,
		new_optimizations = true,
	},

	-- inactive_opacity = 0.7,

	dim_inactive = false,
}

local screen_shader = HOME .. "/.config/hypr/shaders/cinematic.frog"
if io.open(screen_shader, "r") then
	decorations.screen_shader = screen_shader
end

hl.config({ decoration = decorations })
