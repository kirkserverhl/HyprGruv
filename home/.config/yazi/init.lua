local session = require("session")

local linemode = require("linemode")

session:setup({
	sync_yanked = true,
})

linemode:setup()

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
