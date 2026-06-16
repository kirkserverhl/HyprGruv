local decorations = {
	screen_shader = os.getenv("HOME") .. "/.config/hypr/shaders/cinematic.frog",

	rounding = 25,
	rounding_power = 1.0,

	active_opacity = 1.0,
	inactive_opacity = 1.0,

	shadow = {
		enabled = true,
		range = 28,
		render_power = 3,
		color = 0x80900a0a,
	},

	blur = {
		enabled = true,
		size = 10,
		passes = 3,
		noise = 0.01,
		contrast = 0.8,
		vibrancy = 0.2,
	},
}

return decorations
