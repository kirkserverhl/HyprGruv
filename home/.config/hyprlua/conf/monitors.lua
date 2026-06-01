-- conf/monitors.lua
-- Converted from conf/monitor.conf

-- Multi-monitor setup (4 monitors, specific layout + transform)
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output    = "DVI-I-1",
    mode      = "1920x1080@60.00",
    position  = "0x59",
    scale     = 1.2,
    transform = 1,   -- vertical / rotated
})

hl.monitor({
    output   = "DP-1",
    mode     = "1920x1080@60.00",
    position = "900x59",
    scale    = 1.2,
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60.00",
    position = "2501x59",
    scale    = 1.2,
})

hl.monitor({
    output   = "DVI-I-2",
    mode     = "1920x1080@60.00",
    position = "4102x0",
    scale    = 1,
})

-- You can also use the simpler form:
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
