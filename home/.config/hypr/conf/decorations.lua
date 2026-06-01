-- conf/decorations.lua
-- Converted from the active preset: conf/decorations/rounding-more-blur.conf

hl.config({
    decoration = {
        rounding = 10,

        active_opacity   = 1.0,
        inactive_opacity = 0.97,
        fullscreen_opacity = 1.0,

        blur = {
            enabled = true,
            size = 8,
            passes = 4,
            new_optimizations = true,
            ignore_opacity = true,
            xray = true,
            noise = 0.08,
            contrast = 0.9,
            brightness = 0.85,
        },

        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = "0x66000000",
        },
    },
})
