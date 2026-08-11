-- conf/env.lua
-- Converted from conf/environments/default.conf + direct env lines
-- GPU / VA-API vars come from apply-machine-profile.sh (settings/*) when present.

local settings = require("conf.settings")

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

-- GPU / video decode (profile- or hardware-aware defaults)
-- Written by apply-machine-profile.sh → ~/.config/settings/libva_driver.sh etc.
local libva = settings.read("libva_driver", "")
local no_hw = settings.read("wlr_no_hw_cursors", "")
local gpu = settings.read("gpu_vendor", "")

if libva == nil or libva == "" then
	-- Fallback before first profile apply: prefer common iGPU drivers by crude path probes
	if gpu == "nvidia" or gpu == "hybrid-nvidia" then
		libva = "nvidia"
	elseif gpu == "amd" then
		libva = "radeonsi"
	elseif gpu == "intel" then
		libva = "iHD"
	else
		-- Leave unset rather than force a wrong vendor (was hard-coded radeonsi)
		libva = nil
	end
end

if libva and libva ~= "" then
	hl.env("LIBVA_DRIVER_NAME", libva)
end

if no_hw == "1" or no_hw == "true" or gpu == "nvidia" or gpu == "hybrid-nvidia" then
	hl.env("WLR_NO_HARDWARE_CURSORS", "1")
end

-- NVIDIA session (only when profile says so — avoid breaking Intel/AMD)
if libva == "nvidia" then
	hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end

-- Uncomment only for severe rendering problems
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- From main hyprland.conf
local SCRIPTS = require("conf.scripts_path").get()
hl.env("TERMINAL", SCRIPTS .. "/terminal.sh")
-- Electron apps (Obsidian) need a bare browser command, not a launcher script path.
hl.env("BROWSER", settings.read("browser", "brave"))
hl.env("FILEMANAGER", SCRIPTS .. "/filemanager.sh")

-- Misc from other places
hl.env("XDG_MENU_PREFIX", "plasma-")
