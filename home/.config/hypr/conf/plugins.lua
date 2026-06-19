-- conf/plugins.lua
-- Hyprbars plugin configuration for Hyprland 0.55+ Lua config.
-- Buttons are registered once during config parse (never in hl.on handlers —
-- those accumulate across reloads and duplicate buttons).

local SCRIPTS = require("conf.scripts_path").get()

local TOGGLE_SIZE = SCRIPTS .. "/hyprbars-toggle-size.sh"

local function apply_hyprbars()
	if hl.plugin.hyprbars == nil then
		return
	end

	local colors = require("colors.init").load()

	hl.config({
		plugin = {
			hyprbars = {
				-- Match waybar shared/bar-chrome.jsonc height (32)
				bar_height = 32,
				bar_color = "rgba(00000000)",
				bar_blur = false,
				bar_title_enabled = true,
				bar_text_size = 14,
				bar_text_font = "Agave Nerd Font Propo",
				bar_text_align = "center",
				bar_buttons_alignment = "left",
				bar_padding = 14,
				bar_button_padding = 6,
				icon_on_hover = true,
				col = {
					text = colors.fg,
				},
				on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen()'",
			},
		},
	})

	-- Left: close (pink) | Middle: float (grey) | Right: maximize (blue) — starship rainbow slots 1–3
	-- Hyprland 0.55+ needs hl.dsp dispatch strings (plain killactive/togglefloat do not fire).
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_close,
		fg_color = colors.hyprbar_close_fg,
		size = 15,
		icon = "✕",
		action = "hyprctl dispatch 'hl.dsp.window.close()'",
	})
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_minimize,
		fg_color = colors.hyprbar_minimize_fg,
		size = 15,
		icon = "⧉",
		action = "hyprctl dispatch 'hl.dsp.window.float({ action = \"toggle\" })'",
	})
	hl.plugin.hyprbars.add_button({
		bg_color = colors.hyprbar_maximize,
		fg_color = colors.hyprbar_maximize_fg,
		size = 15,
		icon = "+",
		action = "bash " .. TOGGLE_SIZE,
	})
end

apply_hyprbars()