-- conf/env.lua
-- Shared toolkit / session env for every machine.
-- VA-API (LIBVA_DRIVER_NAME) is the only hardware-specific var: it comes from
-- apply-machine-profile.sh → ~/.config/settings/libva_driver.sh.
-- Do not set NVIDIA/WLR leftovers here (__GLX_*, WLR_*, GBM_*) — they leak
-- onto Intel/AMD and Hyprland 0.49+ (Aquamarine) ignores WLR_*.

local settings = require("conf.settings")

-- Hyprland / Wayland (X11 fallbacks where the toolkit uses them)
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- QT apps
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Firefox / Electron: prefer Wayland without hard-failing on X11
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GPU / video decode — profile-written only. Never infer nvidia/hybrid here.
local libva = settings.read("libva_driver", "")
if libva == nil or libva == "" then
	local gpu = settings.read("gpu_vendor", "")
	if gpu == "amd" then
		libva = "radeonsi"
	elseif gpu == "intel" then
		libva = "iHD"
	else
		libva = nil
	end
end

if libva and libva ~= "" then
	hl.env("LIBVA_DRIVER_NAME", libva)
end

-- From main hyprland.conf
local SCRIPTS = require("conf.scripts_path").get()
hl.env("TERMINAL", SCRIPTS .. "/terminal.sh")
-- Electron apps (Obsidian) need a bare browser command, not a launcher script path.
hl.env("BROWSER", settings.read("browser", "brave"))
hl.env("FILEMANAGER", SCRIPTS .. "/filemanager.sh")

-- Misc from other places
hl.env("XDG_MENU_PREFIX", "plasma-")

-- HyprGruv is dark-only. Pin Grok (and any tool that reads these) so a
-- portal flicker or headless/SSH hop cannot flip the TUI to GrokDay.
hl.env("GROK_APPEARANCE", "dark")
hl.env("LC_GROK_APPEARANCE", "dark")
