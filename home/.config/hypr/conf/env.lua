-- conf/env.lua
-- Converted from conf/environments/default.conf + direct env lines

-- Hyprland / Wayland
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- QT apps
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- AMD (Cezanne / Radeon Vega iGPU)
-- These are appropriate for your actual hardware
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")

-- Uncomment the line below only if you run into severe rendering problems
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- From main hyprland.conf
local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
hl.env("TERMINAL", SCRIPTS .. "/terminal.sh")
hl.env("BROWSER", SCRIPTS .. "/browser.sh")
hl.env("FILEMANAGER", SCRIPTS .. "/filemanagers.sh")  -- note: original had typo "filemanagers.sh"

-- Misc from other places
hl.env("XDG_MENU_PREFIX", "plasma-")
