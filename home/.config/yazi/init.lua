local session = require("session")

local linemode = require("linemode")

session:setup({
	sync_yanked = true,
})

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%b %d %H:%M", time)
	else
		time = os.date("%b %d  %Y", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

require("starship"):setup()
require("eza-preview"):setup({
	-- Determines the directory depth level to tree preview (default: 3)
	level = 3,

	-- Whether to follow symlinks when previewing directories (default: false)
	follow_symlinks = false,

	-- Whether to show target file info instead of symlink info (default: false)
	dereference = false,
})
