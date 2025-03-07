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

require("eza-preview"):setup()

require("starship"):setup()
