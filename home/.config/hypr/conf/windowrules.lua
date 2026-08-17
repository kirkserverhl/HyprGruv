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
-- Super+W theme chooser: wide left-right wheel (not the 3×3 wallpaper grid).
hl.window_rule({
    name = "theme-picker-float",
    match = { class = "^(theme-picker)$" },
    float = true,
    center = true,
    size = {1200, 320},
})
-- 'blur' is not a supported field on hl.window_rule (only no_blur is).
-- Use hyprctl to apply the classic "blur" windowrule.
hl.exec_cmd("hyprctl keyword windowrulev2 'blur,class:^(waypaper)$'")
hl.exec_cmd("hyprctl keyword windowrulev2 'blur,class:^(theme-picker)$'")
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

-- Thunar rename dialogs: same process/class as the file manager, so match title.
-- Single-file Rename "foo" and Bulk Rename would otherwise tile and reshuffle the layout.
hl.window_rule({
    name = "thunar-rename",
    match = { class = "^(thunar)$", title = "^Rename " },
    float = true,
    center = true,
    size = {420, 180},
})
hl.window_rule({
    name = "thunar-bulk-rename",
    match = { class = "^(thunar)$", title = "^Bulk Rename" },
    float = true,
    center = true,
    size = {800, 550},
})
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

-- HyprEmoji (MX F6). 342×340 is six emoji columns at the app's default
-- cell size (official default_width 284 is five). Category-nav CSS sets
-- min-width:0 so GTK will accept that width. persistent_size off so a
-- reinstall does not restore Hyprland's 640×340 float default.
local HYPREMOJI_W, HYPREMOJI_H = 342, 340
local HYPREMOJI_SEL = "class:^dev.musagy.hypremoji$"

local function is_hypremoji(w)
    if w == nil then
        return false
    end
    local cls = w.class or w.initial_class or ""
    local title = w.title or w.initial_title or ""
    return title == "HyprEmoji" or cls:find("hypremoji", 1, true)
end

local function place_hypremoji()
    local mon = hl.get_active_monitor()
    if mon == nil then
        return
    end
    local x = mon.x + math.floor(mon.width * 0.75 - HYPREMOJI_W / 2)
    local y = mon.y + math.floor(mon.height * 0.25 - HYPREMOJI_H / 2)
    local dim = HYPREMOJI_W .. " " .. HYPREMOJI_H
    hl.dispatch(hl.dsp.window.float({ action = "on", window = HYPREMOJI_SEL }))
    hl.dispatch(hl.dsp.window.pin({ action = "on", window = HYPREMOJI_SEL }))
    hl.dispatch(hl.dsp.window.set_prop({ prop = "min_size", value = dim, window = HYPREMOJI_SEL }))
    hl.dispatch(hl.dsp.window.set_prop({ prop = "max_size", value = dim, window = HYPREMOJI_SEL }))
    hl.dispatch(hl.dsp.window.resize({
        x = HYPREMOJI_W,
        y = HYPREMOJI_H,
        relative = false,
        window = HYPREMOJI_SEL,
    }))
    hl.dispatch(hl.dsp.window.move({
        x = x,
        y = y,
        relative = false,
        window = HYPREMOJI_SEL,
    }))
end

hl.window_rule({
    name = "hypremoji-float",
    match = { title = "^(HyprEmoji)$" },
    float = true,
    pin = true,
    persistent_size = false,
    min_size = {HYPREMOJI_W, HYPREMOJI_H},
    max_size = {HYPREMOJI_W, HYPREMOJI_H},
    size = {HYPREMOJI_W, HYPREMOJI_H},
})
hl.window_rule({
    name = "hypremoji-float-class",
    match = { class = "^(dev\\.musagy\\.hypremoji)$" },
    float = true,
    pin = true,
    persistent_size = false,
    min_size = {HYPREMOJI_W, HYPREMOJI_H},
    max_size = {HYPREMOJI_W, HYPREMOJI_H},
    size = {HYPREMOJI_W, HYPREMOJI_H},
})

hl.on("window.open", function(w)
    if not is_hypremoji(w) then
        return
    end
    hl.timer(place_hypremoji, { timeout = 200, type = "oneshot" })
end)

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

-- GPU Screen Recorder overlay (gsr-ui — Alt+Z)
hl.window_rule({
    name = "gpu-screen-recorder-overlay",
    match = { class = "^(gpu-screen-recorder|gsr-ui|Gsr-ui)$" },
    float = true,
    pin = true,
    fullscreen = true,
    border_size = 0,
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
