-- conf/monitors.lua
-- Multi-monitor setup (4 monitors, specific layout + transform)
-- Uses desc: matching for stability across docks, DisplayLink/EVDI, and reboots.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Vertical monitor (rotated) explicitly placed on the far left.
hl.monitor({
    output    = "desc:LG Electronics 24CN65",
    mode      = "1920x1080@60.00",
    position  = "0x59",
    scale     = 1.2,
    transform = 1,   -- vertical / rotated 90°
})

-- Horizontal monitors arranged left-to-right after the vertical one.
hl.monitor({
    output   = "desc:LG Electronics LG FULL HD",
    mode     = "1920x1080@60.00",
    position = "900x59",
    scale    = 1.2,
})

hl.monitor({
    output   = "desc:LG Electronics LG Monitor",
    mode     = "1920x1080@60.00",
    position = "2501x59",
    scale    = 1.2,
})

hl.monitor({
    output   = "desc:LG Electronics LG TV",
    mode     = "1920x1080@60.00",
    position = "4102x0",
    scale    = 1,
})

-- Catch-all: ensures any connected monitors not explicitly listed above
-- (or whose names don't perfectly match) still get enabled instead of being disabled.
-- This is the most common reason "extra" monitors stay dark.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
