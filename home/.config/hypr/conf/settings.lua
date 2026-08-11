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

return M
