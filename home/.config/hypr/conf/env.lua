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

local function read_setting(name, fallback)
    local home = os.getenv("HOME") or ""
    local path = home .. "/.config/settings/" .. name .. ".sh"
    local file = io.open(path, "r")
    if not file then
        return fallback
    end
    local line = file:read("l")
    file:close()
    if line and line ~= "" then
        return (line:gsub("%s+", ""))
    end
    return fallback
end

-- From main hyprland.conf
local SCRIPTS = require("conf.scripts_path").get()
hl.env("TERMINAL", SCRIPTS .. "/terminal.sh")
-- Electron apps (Obsidian) need a bare browser command, not a launcher script path.
hl.env("BROWSER", read_setting("browser", "brave"))
hl.env("FILEMANAGER", SCRIPTS .. "/filemanager.sh")

-- Misc from other places
hl.env("XDG_MENU_PREFIX", "plasma-")
