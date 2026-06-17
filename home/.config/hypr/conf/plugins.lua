-- conf/plugins.lua
-- Hyprbars plugin configuration for Hyprland 0.55+ Lua config.
-- hl.keyword does NOT work with the Lua parser — use hl.config + hl.plugin.hyprbars.

local HOME = os.getenv("HOME") or ""

local function apply_hyprbars()
	if hl.plugin.hyprbars == nil then
		return
	end

	local colors = require("colors.init").load()

	hl.config({
		plugin = {
			hyprbars = {
				bar_height = 33,
				bar_color = colors.bg1,
				bar_blur = true,
				bar_title_enabled = true,
				bar_text_size = 14,
				bar_text_font = "Agave Nerd Font",
				bar_text_align = "center",
				bar_buttons_alignment = "left",
				bar_padding = 15,
				bar_button_padding = 6,
				icon_on_hover = true,
				col = {
					text = colors.fg,
				},
				on_double_click = "hyprctl dispatch fullscreen 1",
			},
		},
	})

	-- fg_color is required by the Lua add_button API (icons show on hover).
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_close,
		fg_color = colors.hyprbar_close_fg,
		size = 15,
		icon = "✕",
		action = "hyprctl dispatch killactive",
	})
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_minimize,
		fg_color = colors.hyprbar_minimize_fg,
		size = 15,
		icon = "−",
		action = HOME .. "/.config/hypr/scripts/hyprbars-minimize.sh",
	})
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_maximize,
		fg_color = colors.hyprbar_maximize_fg,
		size = 15,
		icon = "+",
		action = "hyprctl dispatch fullscreen 1",
	})
end

-- Re-register buttons after preReload clears them on `hyprctl reload`.
apply_hyprbars()

-- On login, autostart's hyprpm reload is async — ensure plugin is loaded first.
hl.on("hyprland.start", function()
	os.execute("hyprpm reload >/dev/null 2>&1 || true")
	apply_hyprbars()
end)