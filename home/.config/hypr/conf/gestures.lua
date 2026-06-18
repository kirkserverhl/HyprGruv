-- conf/gestures.lua
-- Converted from conf/gestures.conf + input gesture example

-- 4 finger down gesture
-- In the new Lua API you must use a function for custom actions like "exec"
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.exec_cmd(require("conf.scripts_path").get() .. "/terminal.sh")
    end
})

-- Example 3-finger horizontal workspace swipe (from example docs)
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
