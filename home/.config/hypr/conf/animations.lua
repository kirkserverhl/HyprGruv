local animations = {
	-- MS Standard scheme spatial
	hl_curve = {
		["md3_spatial_fast"] = { type = "spring", mass = 1, stiffness = 600, damping = 49 },
		["md3_spatial_default"] = { type = "spring", mass = 1, stiffness = 300, damping = 35 },
		["md3_spatial_slow"] = { type = "spring", mass = 1, stiffness = 160, damping = 25 },

		["md3_effects_fast"] = { type = "spring", mass = 1, stiffness = 3800, damping = 123 },
		["md3_effects_default"] = { type = "spring", mass = 1, stiffness = 1600, damping = 80 },
		["md3_effects_slow"] = { type = "spring", mass = 1, stiffness = 800, damping = 57 },

		["md3_standard"] = { type = "bezier", points = { 0.2, 0.0, 0.0, 1.0 } },
		["md3_emphasized_accel"] = { type = "bezier", points = { 0.3, 0.0, 0.8, 0.15 } },
	},

	hl_animation = {
		windowsIn = {
			leaf = "windowsIn",
			enabled = true,
			speed = 5,
			spring = "md3_spatial_default",
			style = "popin 92%",
		},
		windowsOut = {
			leaf = "windowsOut",
			enabled = true,
			speed = 5,
			spring = "md3_spatial_default",
			style = "popin 92%",
		},
		windowsMove = {
			leaf = "windowsMove",
			enabled = true,
			speed = 3,
			spring = "md3_spatial_default",
			style = "popin 92%",
		},
		layersIn = {
			leaf = "layersIn",
			enabled = true,
			speed = 3,
			bezier = "md3_standard",
			style = "slide",
		},
		layersOut = {
			leaf = "layersOut",
			enabled = true,
			speed = 2.5,
			bezier = "md3_emphasized_accel",
			style = "slide",
		},
		fade = {
			leaf = "fade",
			enabled = true,
			speed = 2,
			spring = "md3_effects_default",
		},
		fadeOut = {
			leaf = "fadeOut",
			enabled = true,
			speed = 2,
			spring = "md3_spatial_default",
		},
		border = {
			leaf = "border",
			enabled = true,
			speed = 2,
			spring = "md3_effects_default",
		},
		borderangle = {
			leaf = "borderangle",
			enabled = false,
			speed = 2,
			spring = "md3_effects_default",
		},
		workspaces = {
			leaf = "workspaces",
			enabled = true,
			speed = 5,
			spring = "md3_spatial_default",
			style = "slide",
		},
		specialWorkspace = {
			leaf = "specialWorkspace",
			enabled = true,
			speed = 3.5,
			spring = "md3_spatial_fast",
			style = "slidevert",
		},
	},
}

return animations
