-- ~/.config/yazi/init.lua  (Minimal + Stable)

require("full-border"):setup({ type = ui.Border.ROUNDED })

require("smart-enter"):setup({ open_multi = true })

-- Custom linemode
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%b %d %H:%M", time)
	else
		time = os.date("%b %d %Y", time)
	end
	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

-- Simple link indicator
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " → " .. tostring(h.link_to)
	end
	return ""
end, 3300, Status.LEFT)

-- Let Matugen + theme.toml control all colors
