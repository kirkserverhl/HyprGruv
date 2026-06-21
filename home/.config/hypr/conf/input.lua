-- conf/input.lua
-- Converted from conf/keyboard.conf + scattered input settings

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        -- caps:escape = Caps sends Escape (vim-friendly) without Escape toggling Caps Lock.
        -- swapescape caused Caps to flip when Escape was sent (mission control, dialogs, etc.).
        kb_options = "caps:escape",
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

-- Gaming mice expose a phantom "keyboard" HID interface with its own Caps Lock
-- state. When focus follows the mouse, that stale state can flip Caps on.
hl.device({
    name = "logitech-g502-hero-gaming-mouse-keyboard",
    enabled = false,
})
