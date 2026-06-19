-- conf/keybinds.lua
-- ═══════════════════════════════════════════════════════════════════════════════
-- KEYBIND STACK (one rhyme across Hypr + Tmux + Vim)
--
--   Super (main)     → desktop defaults — reach here first on a work day
--   Alt  (alt)       → the *other* option (2nd browser, dev tmux, power tools)
--   Ctrl (apps)      → native app shortcuts (copy/paste/find…) — press directly
--   Ctrl-b (tmux)    → panes/sessions (see ~/.config/tmux/cheatsheet.txt)
--   (none)           → vim / shell typing
--
--   Navigation gesture (same everywhere):
--     dir / hjkl        → focus
--     Shift + dir/hjkl  → resize
--     Ctrl  + dir/hjkl  → move (window or pane)
--
--   Mac bridge (lowest priority — Super only, never steals OS keys):
--     Super+C/V/X/Z/A + Super+Shift+B/I/K → mac-shortcut.sh → Ctrl+*
-- ═══════════════════════════════════════════════════════════════════════════════
-- Backup: keybinds.lua.bak-pre-stack-YYYYMMDD next to this file

local SCRIPTS = require("conf.scripts_path").get()
local MAC     = SCRIPTS .. "/mac-shortcut.sh"
local mainMod = "SUPER"
local altMod  = "ALT"
-- ── helpers ───────────────────────────────────────────────────────────────────

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
    hl.dsp.exec_cmd(string.format(
        "hyprctl notify 1 1400 0 'Gaps: %s (in:%d out:%d)'",
        gap_mode, g.gaps_in, g.gaps_out
    ))
end

-- Hypr direction + parallel arrow/vim keys (tmux uses the same hjkl map)
local DIRECTIONS = {
    { arrow = "left",  vim = "H", hypr = "l", resize = { x = -100, y = 0  } },
    { arrow = "right", vim = "L", hypr = "r", resize = { x =  100, y = 0  } },
    { arrow = "up",    vim = "K", hypr = "u", resize = { x = 0, y = -100 } },
    { arrow = "down",  vim = "J", hypr = "d", resize = { x = 0, y =  100 } },
}

local function bind_navigation_stack()
    for _, d in ipairs(DIRECTIONS) do
        local keys = { d.arrow, d.vim }
        for _, key in ipairs(keys) do
            hl.bind(mainMod .. " + " .. key,
                hl.dsp.focus({ direction = d.hypr }))
            hl.bind(mainMod .. " + SHIFT + " .. key,
                hl.dsp.window.resize({ x = d.resize.x, y = d.resize.y, relative = true }))
            hl.bind(mainMod .. " + CTRL + " .. key,
                hl.dsp.window.move({ direction = d.hypr }))
        end
    end
end

local function mac(action)
    return hl.dsp.exec_cmd(MAC .. " " .. action)
end

-- ── mouse ─────────────────────────────────────────────────────────────────────

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(altMod  .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(altMod  .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAIN (Super) — daily-driver desktop
-- ═══════════════════════════════════════════════════════════════════════════════

-- Launchers
hl.bind(mainMod .. " + SPACE",        hl.dsp.exec_cmd(SCRIPTS .. "/rofi-apps.sh"))
-- Super+Return: plain kitty (or default terminal from ~/.config/settings/terminal.sh)
hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh"))
hl.bind(mainMod .. " + B",            hl.dsp.exec_cmd(SCRIPTS .. "/browser.sh"))
hl.bind(mainMod .. " + Y",            hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh yazi"))
hl.bind(mainMod .. " + N",            hl.dsp.exec_cmd(SCRIPTS .. "/editor-terminal.sh"))
hl.bind(mainMod .. " + PRINT",        hl.dsp.exec_cmd(SCRIPTS .. "/quickshot.sh"))

-- Session / power
hl.bind(mainMod .. " + Q",            hl.dsp.window.close())
hl.bind(mainMod .. " + L",            hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))
hl.bind(mainMod .. " + CTRL + Q",     hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind("CTRL + ALT + DELETE",       hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))

-- Windows & workspaces
hl.bind(mainMod .. " + S",            hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + SHIFT + S",    hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + P",            hl.dsp.window.pseudo())
hl.bind(mainMod .. " + G",            toggle_gaps)
hl.bind(mainMod .. " + W",            hl.dsp.exec_cmd(SCRIPTS .. "/theme-switcher-launch.sh"))
hl.bind(mainMod .. " + Tab",          hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.focus({ workspace = "empty" }))
hl.bind(mainMod .. " + SHIFT + E",    hl.dsp.window.move({ workspace = "empty" }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i,  hl.dsp.exec_cmd(SCRIPTS .. "/moveTo.sh " .. i))
end

hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma",  hl.dsp.layout("move -col"))

-- Focus / resize / move (arrows + hjkl — mirrors tmux)
bind_navigation_stack()

-- Notifications (main = last missed)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/dunst.sh last"))

-- Clipboard history (desktop meta — not app paste)
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(SCRIPTS .. "/cliphist.sh"))

-- Misc main
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(SCRIPTS .. "/unlockroot.sh"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(SCRIPTS .. "/reload-dev-session.sh"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- ALT — the other option (same category, different choice)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Launchers (alt)
hl.bind(altMod .. " + SPACE",  hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"))
hl.bind(altMod .. " + Return", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))
hl.bind(altMod .. " + B",      hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + " .. altMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(altMod .. " + Y",      hl.dsp.exec_cmd(SCRIPTS .. "/filemanager.sh"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))

-- Reload Hyprland config
hl.bind(altMod .. " + R", hl.dsp.exec_cmd("hyprctl reload; hyprctl notify 0 2000 0 'fontsize:13,Hyprland reloaded'"))

-- Screenshots / theme / monitors
hl.bind(altMod .. " + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "/hyprshot.sh"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(SCRIPTS .. "/base16-palette.sh"))
hl.bind(altMod .. " + M",     hl.dsp.exec_cmd(SCRIPTS .. "/monitor-rofi.sh"))
hl.bind(altMod .. " + N",     hl.dsp.exec_cmd("~/.local/bin/night-mode.sh"))

-- Window alt-actions
hl.bind(altMod .. " + V",            hl.dsp.window.float({ action = "toggle" }))
hl.bind(altMod .. " + F",            hl.dsp.window.float({ action = "toggle" }))
hl.bind(altMod .. " + L",            hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"))
hl.bind(altMod .. " + W",            hl.dsp.exec_cmd(SCRIPTS .. "/toggle-bar-mode.sh"))
hl.bind(mainMod .. " + " .. altMod .. " + W", hl.dsp.exec_cmd("~/.local/bin/waybar-layout-switcher"))
hl.bind(altMod .. " + SHIFT + S",    hl.dsp.layout("swapsplit"))

-- Alt+Tab = cycle windows (Super+Tab cycles workspaces)
hl.bind(altMod .. " + Tab",          hl.dsp.exec_cmd("hyprctl dispatch cyclenext"))
hl.bind(altMod .. " + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch cycleprev"))

-- Layout tuning (alt — keeps Super+J/K/L free for vim-nav)
hl.bind(altMod .. " + J",            hl.dsp.exec_cmd("hyprctl keyword general:layout scrolling"))
hl.bind(altMod .. " + SHIFT + J",    hl.dsp.exec_cmd("hyprctl keyword general:layout master"))
hl.bind(altMod .. " + Z",            hl.dsp.layout("addmaster"))
hl.bind(altMod .. " + SUPER + Z",     hl.dsp.layout("removemaster"))
hl.bind(altMod .. " + comma",        hl.dsp.layout("mfact -0.05"))
hl.bind(altMod .. " + period",        hl.dsp.layout("mfact +0.05"))

-- Power tools
hl.bind(altMod .. " + H",            hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh htop"))
hl.bind(altMod .. " + SHIFT + T",    hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh bpytop"))
hl.bind(altMod .. " + P",            hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(altMod .. " + C",            hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"))
hl.bind(mainMod .. " + " .. altMod .. " + P", hl.dsp.exec_cmd(SCRIPTS .. "/software.sh"))

-- Notifications (alt = full menu)
hl.bind(altMod .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/dunst.sh menu"))
hl.bind(altMod .. " + CTRL + SHIFT + A", hl.dsp.exec_cmd("dunstctl close-all"))
hl.bind(altMod .. " + SUPER + A",       hl.dsp.exec_cmd("dunstctl set-paused toggle"))

-- Accessibility zoom
hl.bind(altMod .. " + equal", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')"))
hl.bind(altMod .. " + minus", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- CTRL — applications & meta (press Ctrl directly in apps; these are extras)
-- ═══════════════════════════════════════════════════════════════════════════════

hl.bind("CTRL + F",     hl.dsp.window.fullscreen())
hl.bind("CTRL + P",     hl.dsp.exec_cmd(SCRIPTS .. "/palette.sh"))
hl.bind("CTRL + W",     hl.dsp.exec_cmd("~/.local/bin/waybar-layout-switcher"))
hl.bind("CTRL + SPACE", hl.dsp.exec_cmd(SCRIPTS .. "/fuzzel-keybinds.sh"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAC BRIDGE (lowest priority — optional Cmd muscle memory → Ctrl in app)
-- Super never fights window nav: link/bold/italic sit on Super+Shift
-- ═══════════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + C", mac("copy"))
hl.bind(mainMod .. " + V", mac("paste"))
hl.bind(mainMod .. " + X", mac("cut"))
hl.bind(mainMod .. " + Z", mac("undo"))
hl.bind(mainMod .. " + A", mac("select-all"))
hl.bind(mainMod .. " + SHIFT + B", mac("bold"))
hl.bind(mainMod .. " + SHIFT + I", mac("italic"))
hl.bind(mainMod .. " + SHIFT + K", mac("link"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCTION KEYS (hardware — unchanged)
-- ═══════════════════════════════════════════════════════════════════════════════

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

-- Mission Control: conf/hymission.lua