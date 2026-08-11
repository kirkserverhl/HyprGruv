-- conf/gestures.lua
-- Trackpad gestures. Workspace swipe + scratchpad for laptop profile.

local settings = require("conf.settings")
local SCRIPTS = require("conf.scripts_path").get()
local swipe = settings.read_bool("workspace_swipe", settings.is_laptop())
local is_laptop = settings.is_laptop()

-- 4-finger down → terminal (all machines)
hl.gesture({
	fingers = 4,
	direction = "down",
	action = function()
		hl.exec_cmd(SCRIPTS .. "/terminal.sh")
	end,
})

-- 3-finger horizontal → workspace switch (laptop / when workspace_swipe enabled)
if swipe then
	hl.gesture({
		fingers = 3,
		direction = "horizontal",
		action = "workspace",
	})
end

-- 3-finger vertical → scratchpad work environment (laptop trackpad)
--   swipe up   → show special:scratchpad (spawn terminal if empty)
--   swipe down → hide scratchpad
if is_laptop or swipe then
	hl.gesture({
		fingers = 3,
		direction = "up",
		action = function()
			hl.exec_cmd(SCRIPTS .. "/scratchpad.sh show")
		end,
	})
	hl.gesture({
		fingers = 3,
		direction = "down",
		action = function()
			hl.exec_cmd(SCRIPTS .. "/scratchpad.sh hide")
		end,
	})
end
