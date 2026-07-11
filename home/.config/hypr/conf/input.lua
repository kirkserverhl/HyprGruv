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

-- G502 side buttons mapped to keys/macros in Piper are emitted on this HID
-- "keyboard" interface. enabled=false made Piper look correct while clicks did
-- nothing. Leave it enabled so macros work.
--
-- Tradeoff: this interface has its own Caps Lock LED state and can occasionally
-- flip Caps when focus follows the mouse. Prefer empty kb_options here over
-- disabling the device entirely.
hl.device({
    name = "logitech-g502-hero-gaming-mouse-keyboard",
    enabled = true,
    kb_options = "",
})
