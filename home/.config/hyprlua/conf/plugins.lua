-- conf/plugins.lua
-- Converted from conf/plugins.conf
-- Note: C++ plugins (hyprbars, hyprfocus, etc.) are still configured via the
-- traditional plugin { name { ... } } syntax or through hl.config({ plugin = ... }).
-- Many people keep using the block form even inside .lua files.

-- You can also load/unload from keybinds (see keybinds.lua)

local colors = require("colors.init").load()

hl.config({
    plugin = {
        hyprbars = {
            bar_height = 33,
            -- Use safe concrete colors to avoid "$var" resolution issues
            bar_color = "rgb(141414)",
            bar_blur = true,
            bar_title_enabled = true,
            bar_text_size = 12,
            bar_text_font = "Agave Nerd Font Propo",
            bar_text_align = "center",
            bar_buttons_alignment = "left",
            bar_padding = 15,
            bar_button_padding = 6,
            col = { text = "rgb(e6e6e6)" },

            -- Buttons (macOS style)
            ["hyprbars-button"] = {
                { color = "rgb(ff5f57)", size = 15, action = "hyprctl dispatch killactive" },
                { color = "rgb(ffbd2e)", size = 15, action = "~/.config/hyprgruv/scripts/hyprbars-minimize.sh" },
                { color = "rgb(27c93f)", size = 15, action = "hyprctl dispatch fullscreen 1" },
            },

            on_double_click = "hyprctl dispatch fullscreen 1",
        },

        -- hyprfocus and hyprtrails configs removed because they caused "unknown config key" errors
        -- (plugins may not be installed or option names changed)
        -- hyprfocus = {
        --     mode = "bounce",
        --     bounce_strength = 0.9,
        -- },
        -- hyprtrails = {
        --     color = "rgb(c0c8d5)",
        -- },

        -- hyprwinwrap and hyprscrolling configs removed (causing unknown config key errors)
        -- (plugins may not be installed or config structure changed in this Hyprland version)
        -- hyprwinwrap = {
        --     class = "htop-kitty",
        -- },
        -- hyprscrolling = {
        --     column_width = 0.6,
        -- },


        hymission = {
            layout_engine = "mission-control",
            expand_selected_window = 1,
            overview_focus_follows_mouse = 1,
            multi_workspace_sort_recent_first = 1,
            toggle_switch_mode = 1,
            switch_toggle_auto_next = 1,
            switch_release_key = "Alt_L",
            outer_padding_top = 80,
            outer_padding_bottom = 40,
            outer_padding_left = 40,
            outer_padding_right = 40,
            row_spacing = 28,
            column_spacing = 28,
            workspace_strip_anchor = "left",
            workspace_strip_thickness = 140,
            hide_bar_when_strip = 1,
        },
    }
})
