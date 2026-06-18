-- conf/keybinds.lua
-- Converted (subset) from conf/keybindings/default.conf
-- Full file was 285 lines. Only the most important / frequently used binds converted.
-- Extend as needed using the hl.dsp.* API documented in the wiki.

local SCRIPTS = os.getenv("HOME") .. "/.config/hyprgruv/scripts"
local mainMod = "SUPER"
local mod     = "ALT"

-- Gap toggle state + presets (SUPER + G)
-- State resets on `hyprctl reload` (which is usually what you want).
-- Keep the "normal" values in sync with conf/general.lua.
local gap_mode = "normal"

local GAP_PRESETS = {
    normal  = { gaps_in = 10, gaps_out = 14 },
    minimal = { gaps_in = 2,  gaps_out = 5  },
}

local function toggle_gaps()
    gap_mode = (gap_mode == "normal") and "minimal" or "normal"
    local g = GAP_PRESETS[gap_mode]

    hl.dsp.exec_cmd(string.format(
        "hyprctl --batch 'keyword general:gaps_in %d; keyword general:gaps_out %d'",
        g.gaps_in, g.gaps_out
    ))

    -- Use hyprctl notify (more reliable than notify-send from Lua callbacks)
    hl.dsp.exec_cmd(string.format(
        "hyprctl notify 1 1400 0 'Gaps: switched to %s (in:%d out:%d)'",
        gap_mode, g.gaps_in, g.gaps_out
    ))
end

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Mouse wheel workspace switching
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.focus({ workspace = "empty" }))

-- === MAC-STYLE SHORTCUTS (SUPER/Cmd-like → Ctrl equivalents) ===
-- Super+letter is translated to Ctrl+letter in the focused app (Mac Cmd behavior).
-- Ctrl+C/V/X/Z still work natively when pressed directly — these are additive.
--
-- Implemented via ~/.config/hyprgruv/scripts/mac-shortcut.sh which calls
-- hl.dsp.send_shortcut (Hyprland 0.55+ Lua API). Terminals get Ctrl+Shift+C/V
-- for copy/paste so Ctrl+C is not interpreted as SIGINT.

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh copy"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh paste"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh paste"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh cut"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh undo"))

hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh i"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh u"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(SCRIPTS .. "/mac-shortcut.sh k"))

-- === TERMINALS & LAUNCHERS ===
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))
hl.bind(mod     .. " + Return", hl.dsp.exec_cmd("alacritty"))

-- Browsers: Super+B = default (~/.config/settings/browser.sh), Alt+B = Chrome, Super+Alt+B = Firefox
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(SCRIPTS .. "/browser.sh"))
hl.bind(mod     .. " + B", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + " .. mod .. " + B", hl.dsp.exec_cmd("firefox"))

hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh yazi"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(SCRIPTS .. "/filemanager.sh"))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(SCRIPTS .. "/editor-terminal.sh"))
hl.bind(mod     .. " + H", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh htop"))
hl.bind(mod     .. " + T", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh bpytop"))

hl.bind(mainMod .. " + " .. mod .. " + P", hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh pacseek"))
hl.bind(mod     .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("CTRL + P",        hl.dsp.exec_cmd(SCRIPTS .. "/palette.sh"))
hl.bind(mod     .. " + C", hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"))

-- === ACTIONS ===
hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind(mainMod .. " + L",        hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))
hl.bind("CTRL + ALT + DELETE",    hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind(mod .. " + V",            hl.dsp.window.float({ action = "toggle" }))
-- Also use explicit config for the alternate lock bind so matugen colors (primary/secondary) are always loaded
hl.bind(mod .. " + L",            hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))

-- Bar mode cycle: Waybar → Hyprbars → None → Waybar (ALT+W)
hl.bind(mod .. " + W", hl.dsp.exec_cmd(SCRIPTS .. "/toggle-bar-mode.sh"))
hl.bind("CTRL + W",       hl.dsp.exec_cmd("~/.local/bin/waybar-layout-switcher"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))

-- Screenshots
-- Note: The old unified "screenshot.sh" has been retired.
-- hyprshot.sh = full interactive menu (with timers, modes, editor, etc.)
-- quickshot.sh = instant region → clipboard (fast path)
hl.bind(mod     .. " + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "/hyprshot.sh"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "/quickshot.sh"))

-- Clip history
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(SCRIPTS .. "/cliphist.sh"))

-- Launchers: Super+Space = favorites, Alt+Space = all apps, Ctrl+Space = keybinds
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(SCRIPTS .. "/fuzzel-apps.sh"))
hl.bind(mod     .. " + SPACE", hl.dsp.exec_cmd(SCRIPTS .. "/fuzzel-full.sh"))
hl.bind("CTRL + SPACE",        hl.dsp.exec_cmd(SCRIPTS .. "/fuzzel-keybinds.sh"))

-- Wallpaper / bar / monitor / theme (bar cycle: ALT+W only)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod     .. " + M", hl.dsp.exec_cmd(SCRIPTS .. "/monitor-rofi.sh"))
hl.bind(mainMod .. " + T",        hl.dsp.exec_cmd("pkill -x rofi 2>/dev/null; ~/.config/colorschemes/rofi-launcher.sh"))

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
hl.bind("F5",  hl.dsp.exec_cmd("[fullscreen] kitty --class cmatrix -e cmatrix"))
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

-- Mission Control keybinds live in conf/hymission.lua (uses hl.plugin.hymission API)

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

-- Gaps toggle (normal <-> very minimal)
hl.bind(mainMod .. " + G", toggle_gaps)

-- Master/scrolling layout messages
hl.bind(mod .. " + Z",           hl.dsp.layout("addmaster"))
hl.bind(mod .. " + SUPER + Z",   hl.dsp.layout("removemaster"))
hl.bind(mod .. " + H",           hl.dsp.layout("mfact -0.05"))
hl.bind(mod .. " + L",           hl.dsp.layout("mfact +0.05"))

hl.bind("SUPER + period", hl.dsp.layout("move +col"))
hl.bind("SUPER + comma",  hl.dsp.layout("move -col"))

-- Dunst notifications (short 5s popups for missed ones)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/dunst.sh last"))   -- SUPER + D = last missed (5s)
hl.bind(mod     .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/dunst.sh menu"))   -- ALT + D  = menu of last 10 (5s each)

-- Other Dunst controls
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
