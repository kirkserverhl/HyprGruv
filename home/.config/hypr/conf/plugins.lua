-- conf/plugins.lua
-- Hyprbars plugin configuration for Hyprland 0.55+ Lua config.
--
-- Buttons: hyprbars has add_button only (no remove). The plugin clears its
-- button list on config reload (onPreConfigReload). Calling add_button twice
-- in the same plugin session without a config reload = 6 buttons.
-- Never reset the Lua flag and re-add without unloading the plugin first.

local SCRIPTS = require("conf.scripts_path").get()

local TOGGLE_SIZE = SCRIPTS .. "/hyprbars-toggle-size.sh"
local buttons_registered = false

local function register_hyprbars_buttons(colors)
	if buttons_registered or hl.plugin.hyprbars == nil then
		return
	end

	-- Left: close (orange) | Middle: float (yellow) | Right: maximize (blue)
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

	buttons_registered = true
end

local function apply_hyprbars()
	if hl.plugin.hyprbars == nil then
		return
	end

	package.loaded["colors.init"] = nil
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

	register_hyprbars_buttons(colors)
end

-- Only call before plugin unload (bar-mode). Does NOT clear in-plugin buttons.
function reset_hyprbars_buttons()
	buttons_registered = false
end

-- Safe to call anytime: updates bar config; adds the 3 buttons only once per load.
function reapply_hyprbars()
	apply_hyprbars()
end

apply_hyprbars()