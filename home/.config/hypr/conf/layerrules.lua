-- conf/layerrules.lua
-- Real-time layer blur rules + explicit stacking order.
--
-- Desired layer hierarchy (top to bottom):
--   1. Wlogout + Hyprlock (via hypridle)   → absolute top ("top top layer")
--   2. Waypaper + Rofi app launcher       → below the above two
--   3. Everything else (waybar, notifications, panels, etc.)
--
-- Goal: Stop relying on pre-generated blurred wallpaper images.
-- Instead, let Hyprland blur whatever is behind these tools when they activate.

-- ============================================
-- WLOGOUT (power/logout menu)
-- ============================================
-- When wlogout appears, blur everything behind it.
hl.layer_rule({
    name = "wlogout-blur",
    match = { namespace = "^wlogout$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.0001,   -- very low = lets the strong compositor blur show through
    dim_around = true,
    xray = true,             -- often improves blur quality behind overlays
    order = 200,             -- absolute top layer (above hyprlock)

})

-- ============================================
-- HYPRLOCK (triggered by hypridle)
-- ============================================
-- When hypridle locks the session, hyprlock takes over.
-- This rule ensures the desktop/wallpaper behind the lock UI is blurred.
--
-- Note: hyprlock also has its own `blur_passes` in hyprlock.conf.
-- Combining compositor layer blur + hyprlock internal blur gives a nice effect.
hl.layer_rule({
    name = "hyprlock-blur",
    match = { namespace = "^hyprlock$" },
    blur = true,
    blur_popups = true,
    order = 150,             -- very high, just below wlogout (200)
})

-- (Already using ^hyprlock$ above for precision)

-- ============================================
-- ROFI (application launcher / menus) + WAYPAPER
-- ============================================
-- - Below wlogout (200) and hyprlock (150)
-- - Above normal layers (waybar, notifications, etc.)
-- - Minimal/light blur behind it (not the heavy security blur used for wlogout)
hl.layer_rule({
    match = { namespace = "^rofi$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.08,     -- light blur (higher value = less aggressive blur-through)
    order = 50,              -- sits between normal layers and wlogout
})

hl.layer_rule({
    match = { namespace = "^waypaper$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
    order = 50,
})

-- Force the same blur strength as the global decoration blur (so it matches yazi-in-kitty look)
hl.exec_cmd("hyprctl keyword layerrule 'blurpasses 4, ^waypaper$'")
hl.exec_cmd("hyprctl keyword layerrule 'blursize 8, ^waypaper$'")

-- Fuzzel (app launcher, Super+Space) - match the blur/transparency of yazi running in kitty
hl.layer_rule({
    match = { namespace = "^fuzzel$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
    order = 50,
})

-- Use the exact same blur strength as the global decoration blur for consistency with yazi-in-kitty
hl.exec_cmd("hyprctl keyword layerrule 'blurpasses 4, ^fuzzel$'")
hl.exec_cmd("hyprctl keyword layerrule 'blursize 8, ^fuzzel$'")

-- ============================================
-- Future / Nice to have during overhaul
-- ============================================
-- hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
