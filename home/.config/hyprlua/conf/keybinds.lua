-- conf/keybinds.lua
-- Converted (subset) from conf/keybindings/default.conf
-- Full file was 285 lines. Only the most important / frequently used binds converted.
-- Extend as needed using the hl.dsp.* API documented in the wiki.

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local mainMod = "SUPER"
local mod     = "ALT"

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mouse wheel workspace switching
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.focus({ workspace = "empty" }))

-- === MAC-STYLE SHORTCUTS (send to focused window) ===
-- These simulate Ctrl+Insert / Shift+Insert etc. inside the active app.
-- Fixed syntax for Lua API (window target + repeating flag).
local macShortcutOpts = { repeating = true }

hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.send_shortcut({ mods = "CTRL", key = "V", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + X", hl.dsp.send_shortcut({ mods = "CTRL", key = "X", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + Z", hl.dsp.send_shortcut({ mods = "CTRL", key = "Z", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + I", hl.dsp.send_shortcut({ mods = "CTRL", key = "I", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + U", hl.dsp.send_shortcut({ mods = "CTRL", key = "U", window = "activewindow" }), macShortcutOpts)
hl.bind(mainMod .. " + K", hl.dsp.send_shortcut({ mods = "CTRL", key = "K", window = "activewindow" }), macShortcutOpts)

-- === TERMINALS & LAUNCHERS ===
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh"))
hl.bind(mod     .. " + Return", hl.dsp.exec_cmd("ghostty"))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave-browser"))
hl.bind("CTRL + B",        hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mod     .. " + B", hl.dsp.exec_cmd("firefox"))

hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("kitty yazi"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("dolphin"))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("kitty nvim"))
hl.bind(mod     .. " + H", hl.dsp.exec_cmd("kitty htop"))
hl.bind(mod     .. " + T", hl.dsp.exec_cmd("kitty bpytop"))

hl.bind(mainMod .. " + " .. mod .. " + P", hl.dsp.exec_cmd("kitty pacseek"))
hl.bind(mod     .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("CTRL + P",        hl.dsp.exec_cmd(SCRIPTS .. "/palette.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("smile"))
hl.bind(mod     .. " + C", hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"))

-- === ACTIONS ===
hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind(mainMod .. " + L",        hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))
hl.bind("CTRL + ALT + DELETE",    hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind(mod .. " + V",            hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + L",            hl.dsp.exec_cmd("hyprlock"))

hl.bind(mod .. " + W", hl.dsp.exec_cmd("killall waybar || waybar"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))

-- Screenshots
hl.bind(mod     .. " + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "/hyprshot.sh"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "/quickshot.sh"))

-- Clip history
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(SCRIPTS .. "/cliphist.sh"))

-- Launcher
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -replace -i -terminal kitty"))

-- Wallpaper / bar / monitor / theme
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(SCRIPTS .. "/toggle-waybar.sh"))
hl.bind(mod     .. " + M",        hl.dsp.exec_cmd(SCRIPTS .. "/monitor-rofi.sh"))
hl.bind(mainMod .. " + T",        hl.dsp.exec_cmd("pkill rofi || ~/.config/colorschemes/rofi-launcher.sh"))

-- Misc tools
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(SCRIPTS .. "/unlockroot.sh"))
hl.bind(mod     .. " + N", hl.dsp.exec_cmd("~/.local/bin/night-mode.sh"))

-- === WINDOW MANAGEMENT ===
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("CTRL + F",        hl.dsp.window.fullscreen())
hl.bind(mod     .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + S", hl.dsp.layout("swapsplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- Focus (vim + arrows)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Move windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "d" }))

-- Resize (step)
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 100, y = 0,  relative = true }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 100,  relative = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -100, relative = true }))

-- Function keys (brightness, volume, media, etc.)
hl.bind("F1",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --dec"), { locked = true, repeating = true })
hl.bind("F2",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --inc"), { locked = true, repeating = true })
hl.bind("F3",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --dec"),     { locked = true, repeating = true })
hl.bind("F4",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --inc"),     { locked = true, repeating = true })
hl.bind("F5",  hl.dsp.exec_cmd(SCRIPTS .. "/cmatrix-saver.sh"))
hl.bind("F6",  hl.dsp.exec_cmd("smile"))
hl.bind("F7",  hl.dsp.exec_cmd(SCRIPTS .. "/hyprshot.sh"))
hl.bind("F8",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle-mic"))
hl.bind("F9",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("F10", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("F12", hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle"), { locked = true })

-- Workspace numbers (1-9)
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + E", hl.dsp.window.move({ workspace = "empty" }))

-- Tab / overview
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

hl.bind(mod .. " + Tab",         hl.dsp.exec_cmd("snappy-switcher next"))
hl.bind(mod .. " + SUPER + Tab", hl.dsp.exec_cmd("snappy-switcher prev"))

-- Mission Control (hymission plugin)
hl.bind(mod .. " + grave",       hl.dsp.exec_cmd("hymission:toggle forceall"))
hl.bind(mod .. " + SHIFT + grave", hl.dsp.exec_cmd("hymission:toggle onlycurrentworkspace"))
hl.bind(mod .. " + down",        hl.dsp.exec_cmd("hymission:toggle forceall"))

-- Move all windows to workspace (script)
for i = 1, 9 do
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.exec_cmd(SCRIPTS .. "/moveTo.sh " .. i))
end

-- Zoom / accessibility (cursor zoom)
hl.bind(mod .. " + equal", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')"))
hl.bind(mod .. " + minus", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')"))

-- OBS pass-through example
-- Note: Original used a very specific "Control_L + Super" combo.
-- Using a simpler SUPER + R here because the Lua bind string parser is stricter.
hl.bind("SUPER + R", hl.dsp.pass({ window = "class:^(com\\.obsproject\\.Studio)$" }))

-- Layout switching (scrolling <-> master)
hl.bind(mainMod .. " + J",       hl.dsp.exec_cmd("hyprctl keyword general:layout scrolling"))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd("hyprctl keyword general:layout master"))

-- Master/scrolling layout messages
hl.bind(mod .. " + Z",           hl.dsp.layout("addmaster"))
hl.bind(mod .. " + SUPER + Z",   hl.dsp.layout("removemaster"))
hl.bind(mod .. " + H",           hl.dsp.layout("mfact -0.05"))
hl.bind(mod .. " + L",           hl.dsp.layout("mfact +0.05"))

hl.bind("SUPER + period", hl.dsp.layout("move +col"))
hl.bind("SUPER + comma",  hl.dsp.layout("move -col"))

-- Dunst
hl.bind(mod .. " + A",               hl.dsp.exec_cmd("dunstctl history-pop"))
hl.bind(mod .. " + CTRL + SHIFT + A", hl.dsp.exec_cmd("dunstctl close-all"))
hl.bind(mod .. " + SUPER + A",       hl.dsp.exec_cmd("dunstctl set-paused toggle"))

-- Plugin load/unload examples (hyprbars)
local hyprbars = "/var/cache/hyprpm/kirk/hyprland-plugins/hyprbars.so"
hl.bind(mainMod .. " + R",       hl.dsp.exec_cmd("hyprctl plugin load " .. hyprbars))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl plugin unload " .. hyprbars))

-- =============================================
-- TODO: The original file had more (some duplicates, zoom reset, etc.)
-- Add any missing ones you use daily using the same hl.bind + hl.dsp.* pattern.
-- =============================================
