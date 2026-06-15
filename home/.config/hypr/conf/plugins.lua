-- conf/plugins.lua
-- Converted from conf/plugins.conf
-- Note: C++ plugins (hyprbars, hyprfocus, etc.) are still configured via the
-- traditional plugin { name { ... } } syntax or through hl.config({ plugin = ... }).
-- Many people keep using the block form even inside .lua files.

-- You can also load/unload from keybinds (see keybinds.lua)

-- (Optional) Source Matugen variables if you still want to use traditional
-- plugin { } blocks for other plugins. Not required for the hyprbars config below.
-- source = "~/.config/hypr/colors/custom/matugen.conf"

-- Hyprbars configuration using hl.keyword.
-- This is the most reliable way to configure hyprbars with dynamic colors
-- from the Lua color loader without "unknown key" or legacy block parser errors.
--
-- IMPORTANT: We load colors *inside* the handler so that `hyprctl reload`
-- (triggered by matugen post_hook) always picks up the latest matugen palette.
local function apply_hyprbars()
	local colors = require("colors.init").load()

	hl.keyword("plugin:hyprbars:bar_height", 33)
	hl.keyword("plugin:hyprbars:bar_color", colors.bg1)
	hl.keyword("plugin:hyprbars:bar_blur", true)
	hl.keyword("plugin:hyprbars:bar_title_enabled", true)
	hl.keyword("plugin:hyprbars:bar_text_size", 14)
	hl.keyword("plugin:hyprbars:bar_text_font", "Agave Nerd Font Propo")
	hl.keyword("plugin:hyprbars:bar_text_align", "center")
	hl.keyword("plugin:hyprbars:bar_buttons_alignment", "left")
	hl.keyword("plugin:hyprbars:bar_padding", 15)
	hl.keyword("plugin:hyprbars:bar_button_padding", 6)
	hl.keyword("plugin:hyprbars:col.text", colors.fg)
	hl.keyword("plugin:hyprbars:on_double_click", "hyprctl dispatch fullscreen 1")

	-- Window control buttons using your starship matugen colors
	hl.keyword("plugin:hyprbars:hyprbars-button", colors.hyprbar_close .. ", 15, , hyprctl dispatch killactive")
	hl.keyword(
		"plugin:hyprbars:hyprbars-button",
		colors.hyprbar_minimize .. ", 15, , ~/.config/hypr/scripts/hyprbars-minimize.sh"
	)
	hl.keyword("plugin:hyprbars:hyprbars-button", colors.hyprbar_maximize .. ", 15, , hyprctl dispatch fullscreen 1")
end

hl.on("hyprland.start", apply_hyprbars)
hl.on("config.reloaded", apply_hyprbars)

-- Hot-edge plugin (direct .so from misc.conf)
-- hl.config({
--     plugin = {
--         ["hot-edge"] = { ... }   -- if the plugin supports it
--     }
-- })
