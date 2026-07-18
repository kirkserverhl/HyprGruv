-- conf/windowrules.lua
-- Converted (large subset) from conf/windowrules/default.conf (405 lines original)
-- Uses the modern hl.window_rule({ name, match = {...}, ... }) syntax.

-- Named floating utility preset (can be referenced or just duplicated)
local float_utils = {
    float = true,
    center = true,
    size = {900, 700},
}

-- pavucontrol dropdown (waybar volume left-click)
hl.window_rule({
    name = "pavucontrol-dropdown",
    match = { tag = "pavu-dropdown" },
    float = true,
    pin = true,
    animation = "slidevert",
})

-- pavucontrol full panel (waybar volume right-click)
hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(org.pulseaudio.pavucontrol)$", tag = "negative:pavu-dropdown" },
    float = true,
    size = {780, 620},
    move = "100%-w-24 24",
    pin = true,
})

-- Network Manager
hl.window_rule({
    name = "nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    size = {700, 600},
    move = "100%-w-20 20",
})

-- Blueberry Bluetooth manager (launched from Waybar)
hl.window_rule({
    name = "blueberry-float",
    match = { class = "^(blueberry.py)$" },
    float = true,
    size = {780, 680},
    move = "100%-w-20 20",
})

-- System monitors (htop / bpytop / btop)
hl.window_rule({
    name = "htop-float",
    match = { title = "^(htop)$" },
    float = true,
    size = {900, 600},
    move = "100%-w-20 20",
})

hl.window_rule({
    name = "bpytop-float",
    match = { title = "^(btop|bpytop)$" },
    float = true,
    size = {1000, 700},
    move = "100%-w-20 20",
})

-- Common floating apps using the preset idea
hl.window_rule({
    name = "waypaper-float",
    match = { class = "^(waypaper)$" },
    float = true,
    center = true,
    size = {820, 600},
})
-- 'blur' is not a supported field on hl.window_rule (only no_blur is).
-- Use hyprctl to apply the classic "blur" windowrule.
hl.exec_cmd("hyprctl keyword windowrulev2 'blur,class:^(waypaper)$'")
hl.exec_cmd("hyprctl keyword windowrulev2 'blur,class:^(wallpaper-picker\\.py)$'")
hl.window_rule({
    name = "wallpaper-picker-float",
    match = { class = "^(wallpaper-picker\\.py)$", title = "^Waypaper$" },
    float = true,
    center = true,
    size = {820, 600},
})

-- GTK Settings (nwg-look)
hl.window_rule({
    name = "nwg-look-float",
    match = { class = "^(nwg-look)$" },
    float = true,
    center = true,
    size = {820, 500},
})

-- Display configuration (wdisplays)
hl.window_rule({
    name = "wdisplays-float",
    match = { class = "^(wdisplays)$" },
    float = true,
    center = true,
    size = {900, 650},
})
hl.window_rule({ name = "nemo-float",      match = { class = "^(nemo)$" },       float = true })
-- Removed: This was too broad and made every kitty window float.
-- The original only floated specific kitty instances (htop, yazi, etc.) via title rules below.
-- hl.window_rule({ name = "kitty-float", match = { class = "^(kitty)$" }, float = true })
-- hl.window_rule({ name = "smile-float",     match = { class = "^(smile)$" },      float = true })  -- replaced by hypremoji

-- Note: soundsbored rofi is layer-shell on Wayland (even with -normal-window),
-- so window rules cannot place it. Corner placement is in config-soundsbored.rasi.
hl.window_rule({ name = "rofi-float",      match = { class = "^(rofi|Rofi)$" },  float = true })
-- These two are also quite broad. Comment them out if you want normal alacritty/ghostty to tile.
-- hl.window_rule({ name = "alacritty-float", match = { class = "^(alacritty)$" },  float = true })
-- hl.window_rule({ name = "ghostty-float",   match = { class = "^(ghostty)$" },    float = true })

-- Emoji picker removed from default install (hypremoji/smile optional)

-- (old) smile emoji picker rule kept for reference
-- hl.window_rule({
--     name = "emoji-picker",
--     match = { class = "(it.mijorus.smile)" },
--     float = true,
--     pin = true,
--     move = { "(monitor_w*1)-window_w-20", "48" },
-- })

-- Hyprland share picker
hl.window_rule({
    name = "hyprland-share-picker",
    match = { class = "(hyprland-share-picker)" },
    float = true,
    pin = true,
    size = {600, 400},
})

-- dotfiles-floating (generic large floating tool)
hl.window_rule({
    name = "dotfiles-floating",
    match = { class = "^(dotfiles-floating)$" },
    float = true,
    center = true,
    size = {1000, 700},
    pin = true,
})

-- HyprGruv first-login welcome (package sync + settings handoff)
hl.window_rule({
    name = "hyprgruv-welcome",
    match = {
        class = "^(dotfiles-floating)$",
        title = "^(HyprGruv Welcome)$",
    },
    float = true,
    center = true,
    size = {760, 420},
    pin = true,
})

-- Color Palette chooser (manual via Ctrl+P → palette.sh)
-- Uses a compact size tuned for the 70c x 24c kitty overrides inside palette.sh
-- plus explicit title match for precision (the script forces the title via OSC).
hl.window_rule({
    name = "color-palette",
    match = {
        class = "^(dotfiles-floating)$",
        title = "^(Color Palette)$",
    },
    float = true,
    center = true,
    size = {880, 540},
    pin = true,
})

-- Root Unlock tool (very wide)
hl.window_rule({
    name = "unlockroot",
    match = {
        class = "^(dotfiles-floating)$",
        title = "^(Root Unlock)$",
    },
    float = true,
    center = true,
    size = {1380, 860},
})

-- System updates terminal
hl.window_rule({
    name = "hypr-updates",
    match = { class = "^(hypr-updates)$" },
    float = true,
    center = true,
    size = {1100, 800},
})

-- Picture-in-Picture
hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
    move = { "(monitor_w*0.695)", "(monitor_h*0.04)" },
})

-- yazi floating (launch with kitty --class yazi, etc.)
hl.window_rule({
    name = "yazi-float",
    match = { class = "^(yazi)$" },
    float = true,
    center = true,
    size = {1000, 700},
})

-- pacseek floating (launch with kitty --class pacseek, etc.)
hl.window_rule({
    name = "pacseek-float",
    match = { class = "^(pacseek)$" },
    float = true,
    center = true,
    size = {1000, 700},
})

-- Basic cmatrix (F5): fullscreen on the focused monitor
hl.window_rule({
    name = "cmatrix",
    match = { class = "^(cmatrix)$" },
    float = true,
    border_size = 0,
    fullscreen = true,
})

-- Generic floating utility windows (example of using the preset pattern)
hl.window_rule({
    name = "generic-util-1",
    match = { class = "^(pavucontrol|blueman-manager|blueberry.py)$" },
    float = true,
    center = true,
    size = {900, 700},
})

-- Suppress maximize for everything (very useful)
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some XWayland drag issues
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Extra polish for cmatrix (pure look, no wallpaper blur bleeding through)
hl.exec_cmd("hyprctl keyword windowrulev2 'noblur,class:^(cmatrix)$'")
hl.exec_cmd("hyprctl keyword windowrulev2 'animation fade,class:^(cmatrix)$'")

-- =============================================
-- TODO / REMAINING
-- The original had many more specific title+class combinations for htop/bpytop/yazi
-- inside kitty, plus several duplicates and "windowrule = match:..." old syntax lines.
-- Add any you still need using the hl.window_rule table form above.
-- Named rules can later be toggled with :set_enabled(false)
-- =============================================
