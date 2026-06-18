-- conf/layerrules.lua
-- Real-time layer blur rules + explicit stacking order.
--
-- Runtime tuning: ~/.config/hypr/scripts/apply-hypr-blur.sh (blur-tuner / hyprgruv-settings)
-- updates these named rules via hyprctl eval after load.
--
-- Desired layer hierarchy (top to bottom):
--   1. Wlogout + Hyprlock (via hypridle)   → absolute top ("top top layer")
--   2. Waypaper + Rofi app launcher       → below the above two
--   3. Everything else (waybar, notifications, panels, etc.)
--
-- Goal: Stop relying on pre-generated blurred wallpaper images.
-- Instead, let Hyprland blur whatever is behind these tools when they activate.
--
-- Note: Hyprland 0.55 layer rules do not support per-layer blur size/passes.
-- Layer blur strength follows decoration.blur; ignore_alpha controls visibility.

-- ============================================
-- WLOGOUT (power/logout menu)
-- ============================================
hl.layer_rule({
    name = "wlogout-blur",
    match = { namespace = "^wlogout$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.0001,
    dim_around = true,
    xray = true,
    order = 200,
})

-- ============================================
-- HYPRLOCK (triggered by hypridle)
-- ============================================
hl.layer_rule({
    name = "hyprlock-blur",
    match = { namespace = "^hyprlock$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.05,
    order = 150,
})

-- ============================================
-- ROFI (application launcher / menus) + WAYPAPER
-- ============================================
hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "^rofi$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
    order = 50,
})

hl.layer_rule({
    name = "waypaper-blur",
    match = { namespace = "^waypaper$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
    order = 50,
})

-- Fuzzel (app launcher, Super+Space)
hl.layer_rule({
    name = "fuzzel-blur",
    match = { namespace = "^fuzzel$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
    order = 50,
})

-- ============================================
-- Future / Nice to have during overhaul
-- ============================================
-- hl.layer_rule({ match = { namespace = "notifications" }, blur = true })