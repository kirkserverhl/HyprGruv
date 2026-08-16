-- conf/settings.lua
-- Shared readers for ~/.config/settings/<name>.sh (one value per file).
-- Written by setup defaults + apply-machine-profile.sh

local M = {}

local function trim(s)
	if not s then
		return s
	end
	return (s:gsub("%s+", ""))
end

function M.read(name, fallback)
	local home = os.getenv("HOME") or ""
	local path = home .. "/.config/settings/" .. name .. ".sh"
	local file = io.open(path, "r")
	if not file then
		return fallback
	end
	local line = file:read("l")
	file:close()
	if line and line ~= "" then
		return trim(line)
	end
	return fallback
end

function M.read_bool(name, fallback)
	local v = M.read(name, nil)
	if v == nil then
		return fallback
	end
	v = string.lower(tostring(v))
	if v == "1" or v == "true" or v == "yes" or v == "on" then
		return true
	end
	if v == "0" or v == "false" or v == "no" or v == "off" then
		return false
	end
	return fallback
end

function M.read_number(name, fallback)
	local v = M.read(name, nil)
	if v == nil then
		return fallback
	end
	local n = tonumber(v)
	if n == nil then
		return fallback
	end
	return n
end

--- machine profile: "laptop" | "desktop" (default desktop)
function M.machine()
	local m = M.read("machine", nil)
	if m == "laptop" or m == "desktop" then
		return m
	end
	-- Fallback: state file from apply-machine-profile
	local home = os.getenv("HOME") or ""
	local state = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/hyprgruv/machine"
	local f = io.open(state, "r")
	if f then
		local line = f:read("l")
		f:close()
		line = trim(line or "")
		if line == "laptop" or line == "desktop" then
			return line
		end
	end
	return "desktop"
end

function M.is_laptop()
	return M.machine() == "laptop"
end

--- Parse ~/.config/settings/bar-sizes.sh for this machine.
--- Returns a table with height, margin_top, margin_x, font_size,
--- font_emphasis, font_center, hyprbars_text, module_min_height.
function M.bar_sizes()
	local prefix = M.is_laptop() and "LAPTOP_" or "DESKTOP_"
	local sizes = {
		height = M.is_laptop() and 24 or 32,
		margin_top = M.is_laptop() and 4 or 5,
		margin_x = M.is_laptop() and 10 or 14,
		font_size = M.is_laptop() and 12 or 16,
		font_emphasis = M.is_laptop() and 14 or 18,
		font_center = M.is_laptop() and 15 or 20,
		hyprbars_text = M.is_laptop() and 11 or 14,
		module_min_height = M.is_laptop() and 20 or 28,
	}
	local home = os.getenv("HOME") or ""
	local file = io.open(home .. "/.config/settings/bar-sizes.sh", "r")
	if not file then
		return sizes
	end
	local key_map = {
		BAR_HEIGHT = "height",
		BAR_MARGIN_TOP = "margin_top",
		BAR_MARGIN_X = "margin_x",
		FONT_SIZE = "font_size",
		FONT_SIZE_EMPHASIS = "font_emphasis",
		FONT_SIZE_CENTER = "font_center",
		HYPRBARS_TEXT = "hyprbars_text",
		MODULE_MIN_HEIGHT = "module_min_height",
	}
	for line in file:lines() do
		local key, val = line:match("^%s*" .. prefix .. "([A-Z_]+)%s*=%s*([%d%.]+)")
		if key and val and key_map[key] then
			sizes[key_map[key]] = tonumber(val) or sizes[key_map[key]]
		end
	end
	file:close()
	return sizes
end

return M
