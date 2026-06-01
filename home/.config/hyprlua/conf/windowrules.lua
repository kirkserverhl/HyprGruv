-- conf/windowrules.lua
-- Converted (large subset) from conf/windowrules/default.conf (405 lines original)
-- Uses the modern hl.window_rule({ name, match = {...}, ... }) syntax.

-- Named floating utility preset (can be referenced or just duplicated)
local float_utils = {
    float = true,
    center = true,
    size = {900, 700},
}

-- pavucontrol
hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
    size = {600, 500},
    move = "100%-w-20 20",
})

-- Network Manager
hl.window_rule({
    name = "nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    size = {700, 600},
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
hl.window_rule({ name = "waypaper-float",  match = { class = "^(waypaper)$" },  float = true })
hl.window_rule({ name = "nemo-float",      match = { class = "^(nemo)$" },       float = true })
-- Removed: This was too broad and made every kitty window float.
-- The original only floated specific kitty instances (htop, yazi, etc.) via title rules below.
-- hl.window_rule({ name = "kitty-float", match = { class = "^(kitty)$" }, float = true })
hl.window_rule({ name = "smile-float",     match = { class = "^(smile)$" },      float = true })
hl.window_rule({ name = "rofi-float",      match = { class = "^(rofi|Rofi)$" },  float = true })
-- These two are also quite broad. Comment them out if you want normal alacritty/ghostty to tile.
-- hl.window_rule({ name = "alacritty-float", match = { class = "^(alacritty)$" },  float = true })
-- hl.window_rule({ name = "ghostty-float",   match = { class = "^(ghostty)$" },    float = true })

-- VLC
hl.window_rule({
    name = "vlc-float",
    match = { class = "^(vlc)$" },
    float = true,
})

-- Emoji picker (smile) - precise positioning
hl.window_rule({
    name = "emoji-picker",
    match = { class = "(it.mijorus.smile)" },
    float = true,
    pin = true,
    move = { "(monitor_w*1)-window_w-40", "90" },
})

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

-- CMatrix fullscreen special case
-- Force fullscreen via rule so it appears directly in fullscreen (no floating flash).
-- The script still does focus + reinforcement for multi-monitor correctness.
hl.window_rule({
    name = "cmatrix-full",
    match = { class = "^(cmatrix-full)$" },
    float = true,
    border_size = 0,
    fullscreen = true,
})

-- Extra properties for the matrix screensaver
hl.exec_cmd("hyprctl keyword windowrulev2 'noblur,class:^(cmatrix-full)$'")

-- Use a dedicated fade animation for this overlay (nice open/close feel)
hl.exec_cmd("hyprctl keyword windowrulev2 'animation fade,class:^(cmatrix-full)$'")

-- yazi floating
hl.window_rule({
    name = "yazi-float",
    match = { class = "^(yazi)$" },
    float = true,
})

-- Generic floating utility windows (example of using the preset pattern)
hl.window_rule({
    name = "generic-util-1",
    match = { class = "^(pavucontrol|blueman-manager)$" },
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

-- =============================================
-- TODO / REMAINING
-- The original had many more specific title+class combinations for htop/bpytop/yazi
-- inside kitty, plus several duplicates and "windowrule = match:..." old syntax lines.
-- Add any you still need using the hl.window_rule table form above.
-- Named rules can later be toggled with :set_enabled(false)
-- =============================================
