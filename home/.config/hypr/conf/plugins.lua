-- conf/plugins.lua
-- Hyprbars plugin configuration for Hyprland 0.55+ Lua config.
-- hl.keyword does NOT work with the Lua parser — use hl.config + hl.plugin.hyprbars.

local HOME = os.getenv("HOME") or ""

-- add_button appends; never call register twice on the same plugin instance.
local buttons_registered = false

local function apply_hyprbars_config(colors)
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
				on_double_click = "hyprctl dispatch fullscreen 1",
			},
		},
	})
end

local function register_hyprbars_buttons(colors)
	if buttons_registered or hl.plugin.hyprbars == nil then
		return
	end

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

	buttons_registered = true
end

local function apply_hyprbars()
	if hl.plugin.hyprbars == nil then
		return
	end

	local colors = require("colors.init").load()
	apply_hyprbars_config(colors)
	register_hyprbars_buttons(colors)
end

local function apply_hyprbars_config_only()
	if hl.plugin.hyprbars == nil then
		return
	end
	local colors = require("colors.init").load()
	apply_hyprbars_config(colors)
end

-- config.reloaded must not re-add buttons (plugin instance keeps them → duplicates).
hl.on("config.reloaded", function()
	apply_hyprbars_config_only()
end)

function reset_hyprbars_buttons()
	buttons_registered = false
end

-- Only call after a fresh `hyprctl plugin load`.
function reapply_hyprbars()
	buttons_registered = false
	apply_hyprbars()
end