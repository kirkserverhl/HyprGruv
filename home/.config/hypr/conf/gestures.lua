-- conf/gestures.lua
-- Workspace swipe enabled for laptop profile (settings/workspace_swipe.sh).

local settings = require("conf.settings")
local swipe = settings.read_bool("workspace_swipe", settings.is_laptop())

-- 4 finger down → terminal
hl.gesture({
	fingers = 4,
	direction = "down",
	action = function()
		hl.exec_cmd(require("conf.scripts_path").get() .. "/terminal.sh")
	end,
})

-- 3-finger horizontal workspace swipe (trackpads)
if swipe then
	hl.gesture({
		fingers = 3,
		direction = "horizontal",
		action = "workspace",
	})
end
