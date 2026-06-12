local M = {}

local lighten = require("base46.colors").change_hex_lightness

M.base_30 = {
	white = "#f1dedd",
	black = "#1a1111",
	darker_black = lighten("#1a1111", -3),
	black2 = lighten("#1a1111", 6),
	one_bg = lighten("#1a1111", 10),
	one_bg2 = lighten("#1a1111", 16),
	one_bg3 = lighten("#1a1111", 22),
	grey = "#534342",
	grey_fg = lighten("#534342", -10),
	grey_fg2 = lighten("#534342", -20),
	light_grey = "#a08c8b",
	red = "#ffb4ab",
	baby_pink = lighten("#ffb4ab", 10),
	pink = "#e2c28c",
	line = "#a08c8b",
	green = "#b7d085",
	vibrant_green = lighten("#b7d085", 10),
	blue = "#cebdfe",
	nord_blue = lighten("#cebdfe", 10),
	yellow = "#dec56e",
	sun = lighten("#dec56e", 10),
	purple = "#e2c28c",
	dark_purple = lighten("#e2c28c", -10),
	teal = "#5d3f3d",
	orange = "#ffb4ab",
	cyan = "#84d5c4",
	statusline_bg = lighten("#1a1111", 6),
	pmenu_bg = "#534342",
	folder_bg = lighten("#ffb3ae", 0),
	lightbg = lighten("#1a1111", 10),
}

M.base_16 = {
	base00 = "#1a1111",
	base01 = lighten("#534342", 0),
	base02 = lighten("#534342", 3),
	base03 = lighten("#a08c8b", 0),
	base04 = lighten("#d8c2c0", 0),
	base05 = "#f1dedd",
	base06 = lighten("#f1dedd", 0),
	base07 = "#1a1111",
	base08 = "#ffb4ab",
	base09 = "#dec56e",
	base0A = "#cebdfe",
	base0B = "#b7d085",
	base0C = "#84d5c4",
	base0D = lighten("#cebdfe", 20),
	base0E = "#e2c28c",
	base0F = "#f1dedd",
}

M.type = "dark"

M.polish_hl = {
	defaults = {
		Comment = {
			italic = true,
			fg = M.base_16.base03,
		},
	},
	Syntax = {
		String = {
			fg = "#e2c28c",
		},
	},
	treesitter = {
		["@comment"] = {
			fg = M.base_16.base03,
		},
		["@string"] = {
			fg = "#e2c28c",
		},
	},
}

return M
