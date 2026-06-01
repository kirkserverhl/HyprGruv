-- conf/input.lua
-- Converted from conf/keyboard.conf + scattered input settings

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:swapescape",
        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        sensitivity = 0.1,   -- from misc.conf override

        touchpad = {
            natural_scroll = false,
            scroll_factor  = 1.0,
        },
    },
})

-- Per-device example (from original comments)
-- hl.device({
--     name = "epic-mouse-v1",
--     sensitivity = -0.5,
-- })
