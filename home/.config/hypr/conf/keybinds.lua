-- conf/keybinds.lua
-- ═══════════════════════════════════════════════════════════════════════════════
-- KEYBIND STACK (one rhyme across Hypr + Tmux + Vim)
--
--   Super (main)     → desktop defaults — reach here first on a work day
--   Alt  (alt)       → the *other* option (2nd browser, power tools)
--   Super+Alt+Return → dev tmux workspace (not bare Alt+Return — kew owns Alt+Enter)
--   Ctrl (apps)      → NEVER bind bare Ctrl+letter globally — apps own Find/Print/Save…
--                      Only OK with Super/Alt chorded: Super+Ctrl+H (move), Ctrl+Alt+Del
--   Ctrl-b (tmux)    → panes/sessions (see ~/.config/tmux/cheatsheet.txt)
--   (none)           → vim / shell typing
--
--   Navigation gesture (same everywhere):
--     dir / hjkl        → focus
--     Shift + dir/hjkl  → resize
--     Ctrl  + dir/hjkl  → move (window or pane)  [only when Super is held]
--
--   Mac bridge (lowest priority — Super only, never steals OS keys):
--     Super+C/V/X/Z/A + Super+Shift+Z/B/I/U → mac-shortcut.sh → Ctrl+*
--     Script delays briefly so Super is released (avoids cccc/vvvv storms).
--     Terminals: primary-selection copy + Ctrl+Shift paste (text only).
--     (link is Super+Shift+U so Super+Shift+K stays resize-up)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Backup: keybinds.lua.bak-pre-stack-YYYYMMDD next to this file
--
-- Rofi cheatsheet (Alt+K) reads descriptions from:
--   1. Trailing comment on the bind line:  hl.bind(...) -- #tag Human label
--   2. Comment on the line above:          -- Human label
--   #tags are searchable in the rofi menu (e.g. #launcher #guest)

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
    hl.config({ general = { gaps_in = g.gaps_in, gaps_out = g.gaps_out } })
    hl.exec_cmd(string.format(
        "hyprctl notify 1 1400 0 'Gaps: %s (in:%d out:%d)'",
        gap_mode, g.gaps_in, g.gaps_out
    ))
end

-- hyprctl keyword does not work with the Lua config parser (0.55+); use hl.config.
-- Layout modes: dwindle (default tiling) ↔ scrolling (column / research).
local layout_mode = "dwindle"

local function apply_layout(name, label)
    layout_mode = name
    hl.config({ general = { layout = name } })
    hl.exec_cmd(string.format(
        "hyprctl notify 0 1600 0 'Layout: %s'",
        label or name
    ))
end

local function set_layout(name, label)
    return function()
        apply_layout(name, label)
    end
end

local function toggle_column_layout()
    if layout_mode == "scrolling" then
        apply_layout("dwindle", "dwindle (tiling)")
    else
        apply_layout("scrolling", "columns (research)")
    end
end

-- Hypr direction + parallel arrow/vim keys (tmux uses the same hjkl map)
--
--   Super + left/right/up/down   OR   Super + H/J/K/L
--     focus window in that direction
--   Super + Shift + same keys
--     resize active window (hold to repeat)
--   Super + Ctrl + same keys
--     move/swap window in that direction (hold to repeat)
--
-- Keep Super+Shift+H/J/K/L free of other binds (mac link uses Super+Shift+U).
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
            -- #window Focus window (arrows + hjkl)
            hl.bind(mainMod .. " + " .. key,
                hl.dsp.focus({ direction = d.hypr }))
            -- #window Resize window (arrows + hjkl)
            hl.bind(mainMod .. " + SHIFT + " .. key,
                hl.dsp.window.resize({ x = d.resize.x, y = d.resize.y, relative = true }),
                { repeating = true })
            -- #window Move window (arrows + hjkl)
            hl.bind(mainMod .. " + CTRL + " .. key,
                hl.dsp.window.move({ direction = d.hypr }),
                { repeating = true })
        end
    end
end

-- ── Mac bridge: Super (Cmd muscle memory) → mac-shortcut.sh ─────────────────
-- Script owns terminal vs app logic + delayed wtype (see script header).
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
hl.bind(mainMod .. " + SPACE",        hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh")) -- #launcher #guest Open all apps
-- Super+Return: plain kitty (or default terminal from ~/.config/settings/terminal.sh)
hl.bind(mainMod .. " + Return",       hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh"))
hl.bind(mainMod .. " + KP_Enter",     hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh"))
hl.bind(mainMod .. " + B",            hl.dsp.exec_cmd("google-chrome-stable")) -- #launcher Open Chrome
hl.bind(mainMod .. " + Y",            hl.dsp.exec_cmd(SCRIPTS .. "/yazi.sh")) -- #files Open file manager (yazi)
hl.bind(mainMod .. " + N",            hl.dsp.exec_cmd(SCRIPTS .. "/editor-terminal.sh")) -- #editor Open editor
hl.bind(mainMod .. " + O",            hl.dsp.exec_cmd(SCRIPTS .. "/obsidian.sh")) -- #launcher Open Obsidian
hl.bind(mainMod .. " + SHIFT + A",    hl.dsp.exec_cmd(SCRIPTS .. "/soundsbored.sh")) -- #audio #launcher Open soundsbored
hl.bind(mainMod .. " + SHIFT + M",    hl.dsp.exec_cmd(os.getenv("HOME") .. "/bin/baas-menu")) -- #work #baas #launcher BaaS tech workflows
hl.bind(mainMod .. " + PRINT",        hl.dsp.exec_cmd(SCRIPTS .. "/quickshot.sh")) -- #screenshot Quick screenshot

-- Session / power
-- Lock on Super+Escape (not Super+L) so Super+H/J/K/L stay pure vim focus
hl.bind(mainMod .. " + Q",            hl.dsp.window.close())
hl.bind(mainMod .. " + Escape",       hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf")) -- #session Lock screen
hl.bind(mainMod .. " + CTRL + Q",     hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))
hl.bind("CTRL + ALT + DELETE",       hl.dsp.exec_cmd(SCRIPTS .. "/launch-wlogout.sh"))

-- Windows & workspaces
hl.bind(mainMod .. " + S",            hl.dsp.exec_cmd(SCRIPTS .. "/scratchpad.sh toggle")) -- #window Scratchpad toggle
hl.bind(mainMod .. " + SHIFT + S",    hl.dsp.window.move({ workspace = "special:scratchpad" })) -- #window Move to scratchpad
hl.bind(mainMod .. " + F",            hl.dsp.window.fullscreen()) -- #window Fullscreen (was CTRL+F — that stole Find)
hl.bind(mainMod .. " + P",            hl.dsp.window.pseudo())
hl.bind(mainMod .. " + G",            toggle_gaps)
hl.bind(mainMod .. " + W",            hl.dsp.exec_cmd(SCRIPTS .. "/theme-switcher-launch.sh")) -- #theme Theme → wallpaper → source → apply
-- Super+Tab / Super+Shift+Tab: cycle workspaces on the *current monitor only* (m±1).
-- Does not jump across monitors (unlike the global occupied-cycle script).
hl.bind(mainMod .. " + Tab",          hl.dsp.focus({ workspace = "m+1" })) -- #window Next workspace on this monitor
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" })) -- #window Prev workspace on this monitor
-- Also: Super+Ctrl+Space = first empty; Super+Shift+E = move window to empty
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.focus({ workspace = "empty" })) -- #window First empty workspace
hl.bind(mainMod .. " + SHIFT + E",    hl.dsp.window.move({ workspace = "empty" })) -- #window Move to empty workspace
-- Equal/minus: same monitor-local cycle (handy on laptop)
hl.bind(mainMod .. " + equal",        hl.dsp.focus({ workspace = "m+1" })) -- #window Next workspace on this monitor
hl.bind(mainMod .. " + minus",        hl.dsp.focus({ workspace = "m-1" })) -- #window Prev workspace on this monitor

for i = 1, 9 do
    -- Super+N: focus (creates WS if needed). Empty non-persistent WS drop when left empty.
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i })) -- #window Workspace N
    -- Super+Shift+N: move window there (also creates if needed)
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i })) -- #window Move to workspace N
    hl.bind(mainMod .. " + CTRL + " .. i,  hl.dsp.exec_cmd(SCRIPTS .. "/moveTo.sh " .. i))
end

-- Column view pan (scrolling layout only — no-ops harmlessly in dwindle)
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col")) -- #layout #column Pan view +1 column
hl.bind(mainMod .. " + comma",  hl.dsp.layout("move -col")) -- #layout #column Pan view -1 column

-- Focus / resize / move (arrows + hjkl — mirrors tmux)
bind_navigation_stack()

-- Notifications (main = last missed)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/notifications.sh last"))

-- Clipboard history (desktop meta — not app paste)
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(SCRIPTS .. "/cliphist.sh"))

-- Misc main
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(SCRIPTS .. "/unlockroot.sh"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(SCRIPTS .. "/reload-dev-session.sh"))

-- ═══════════════════════════════════════════════════════════════════════════════
-- ALT — the other option (same category, different choice)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Super+Alt+Return: tmux dev workspace (was Alt+Return — that stole kew's enqueueAndPlay)
hl.bind(mainMod .. " + " .. altMod .. " + Return", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh")) -- #terminal #tmux Dev tmux workspace
hl.bind(mainMod .. " + " .. altMod .. " + KP_Enter", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))
hl.bind(altMod .. " + B",      hl.dsp.exec_cmd("brave")) -- #launcher Open Brave
hl.bind(mainMod .. " + " .. altMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(altMod .. " + Y",      hl.dsp.exec_cmd(SCRIPTS .. "/filemanager.sh"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))
hl.bind(mainMod .. " + SHIFT + KP_Enter", hl.dsp.exec_cmd(SCRIPTS .. "/dev-workspace.sh"))

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
-- Alt+W: cycle Waybar only → Hyprbars only → hidden (lua callback — more reliable than exec_cmd alone)
hl.bind(altMod .. " + W", function()
	hl.exec_cmd("bash " .. SCRIPTS .. "/toggle-bar-mode.sh")
end)
-- Waybar layout rofi: absolute path + lua callback (tilde + bare exec_cmd was silent-failing)
local WAYBAR_LAYOUT = (os.getenv("HOME") or "") .. "/.local/bin/waybar-layout-switcher"
local function open_waybar_layout_switcher()
	hl.exec_cmd("bash " .. WAYBAR_LAYOUT)
end
hl.bind(mainMod .. " + " .. altMod .. " + W", open_waybar_layout_switcher) -- #theme #waybar Select waybar layout
-- Alt+Shift+W: waybar layout/theme picker (Ctrl+W left free for apps — Chrome close-tab, etc.)
hl.bind(altMod .. " + SHIFT + W", open_waybar_layout_switcher) -- #theme #waybar Select waybar layout
hl.bind(altMod .. " + SHIFT + S",    hl.dsp.layout("swapsplit"))

-- Window cycle: Super+Alt+Tab (NOT bare Alt+Tab — that is Mission Control / hymission)
hl.bind(mainMod .. " + " .. altMod .. " + Tab",          hl.dsp.exec_cmd("hyprctl dispatch cyclenext")) -- #window Cycle next window
hl.bind(mainMod .. " + " .. altMod .. " + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch cycleprev")) -- #window Cycle prev window

-- ── Layout: optional column / research mode (scrolling) ─────────────────────
-- Daily default is dwindle. Flip to columns when researching / multi-doc work.
-- Super+hjkl still focus/resize/move; these binds only add column semantics.
--
--   Alt+J              toggle dwindle ↔ columns (research)
--   Alt+Shift+J        force dwindle
--   Super+, / .        pan view along the column tape
--   Alt+, / .          cycle column width (explicit_column_widths)
--   Super+Alt+, / .    swap column with neighbor
--   Alt+Z              promote window to its own column
--   Alt+Shift+Z        consume into previous column (stack)
--   Alt+Shift+F        fit active column into view
hl.bind(altMod .. " + J",            toggle_column_layout) -- #layout #column Toggle columns (research)
hl.bind(altMod .. " + SHIFT + J",    set_layout("dwindle", "dwindle (tiling)")) -- #layout Force dwindle tiling
hl.bind(altMod .. " + comma",        hl.dsp.layout("colresize -conf")) -- #layout #column Narrower column width
hl.bind(altMod .. " + period",       hl.dsp.layout("colresize +conf")) -- #layout #column Wider column width
hl.bind(mainMod .. " + " .. altMod .. " + comma",  hl.dsp.layout("swapcol l")) -- #layout #column Swap column left
hl.bind(mainMod .. " + " .. altMod .. " + period", hl.dsp.layout("swapcol r")) -- #layout #column Swap column right
hl.bind(altMod .. " + Z",            hl.dsp.layout("promote")) -- #layout #column Promote to own column
hl.bind(altMod .. " + SHIFT + Z",    hl.dsp.layout("consume")) -- #layout #column Stack into previous column
hl.bind(altMod .. " + SHIFT + F",    hl.dsp.layout("fit_into_view")) -- #layout #column Fit column into view

-- Power tools
hl.bind(altMod .. " + H",            hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh htop"))
hl.bind(altMod .. " + SHIFT + T",    hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh bpytop"))
hl.bind(altMod .. " + P",            hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(altMod .. " + C",            hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"))
hl.bind(mainMod .. " + " .. altMod .. " + P", hl.dsp.exec_cmd(SCRIPTS .. "/software.sh"))

-- Notifications (alt = full menu)
hl.bind(altMod .. " + D", hl.dsp.exec_cmd(SCRIPTS .. "/notifications.sh menu"))
hl.bind(altMod .. " + CTRL + SHIFT + A", hl.dsp.exec_cmd(SCRIPTS .. "/notifications.sh close-all"))
hl.bind(altMod .. " + SUPER + A",       hl.dsp.exec_cmd(SCRIPTS .. "/notifications.sh toggle-pause"))

-- Accessibility zoom (screen magnifier around cursor — not app content zoom)
hl.bind(altMod .. " + equal", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')"))
hl.bind(altMod .. " + minus", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')"))
-- Ctrl + scroll wheel: same magnifier (steals Ctrl+scroll from apps — browsers/terminals)
hl.bind("CTRL + mouse_up",   hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 1.1}')")) -- #zoom Ctrl+scroll up magnify
hl.bind("CTRL + mouse_down", hl.dsp.exec_cmd("hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor | awk '/^float.*/ {print $2 * 0.9}')")) -- #zoom Ctrl+scroll down demagnify

-- ═══════════════════════════════════════════════════════════════════════════════
-- DESKTOP META (was under bare CTRL — that steals native app shortcuts)
-- Rule: bare Ctrl is reserved for apps (Find, Print, Save, close-tab…).
-- Desktop actions live on Super / Alt only.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Fullscreen moved to Super+F (see MAIN section above).
-- Palette: was CTRL+P (Print in every app) → Super+Shift+C
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(SCRIPTS .. "/palette.sh")) -- #theme Color palette picker
-- Keybind cheatsheet: was also CTRL+SPACE (IME / IDE autocomplete conflict) — Alt+K only
hl.bind(altMod .. " + K", hl.dsp.exec_cmd(SCRIPTS .. "/rofi-keybinds.sh")) -- #guest #help Keybind cheatsheet (tell guests this one)

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAC BRIDGE (lowest priority — optional Cmd muscle memory → Ctrl in app)
-- Super ≈ Cmd. Native Linux Ctrl+* still works. Desktop keeps Super for WM.
-- bold/italic/link on Super+Shift but NOT H/J/K/L (resize). Link = Super+Shift+U.
-- ═══════════════════════════════════════════════════════════════════════════════

hl.bind(mainMod .. " + C", mac("copy"))       -- #mac Cmd+C → copy (Ctrl+C / Ctrl+Shift+C in term)
hl.bind(mainMod .. " + V", mac("paste"))      -- #mac Cmd+V → paste
hl.bind(mainMod .. " + X", mac("cut"))        -- #mac Cmd+X → cut
hl.bind(mainMod .. " + Z", mac("undo"))       -- #mac Cmd+Z → undo
hl.bind(mainMod .. " + SHIFT + Z", mac("redo")) -- #mac Cmd+Shift+Z → redo
hl.bind(mainMod .. " + A", mac("select-all")) -- #mac Cmd+A → select all
hl.bind(mainMod .. " + SHIFT + B", mac("bold"))   -- #mac Bold
hl.bind(mainMod .. " + SHIFT + I", mac("italic")) -- #mac Italic
-- Super+Shift+K is resize-up (vim nav); use U for URL/link instead
hl.bind(mainMod .. " + SHIFT + U", mac("link")) -- #mac Cmd+K → link (was Super+Shift+K)

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCTION KEYS — per-keyboard (match each board's F-row legends)
-- Hyprland device-specific binds: only the listed keyboards trigger each map.
-- FN note: firmware chooses whether bare F-row is F1–F12 or XF86 media keys.
-- Laptop map binds both so either FN layer works; external boards keep own maps.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Device name lists from `hyprctl devices` (include all HID interfaces per board)
local KB_HP = {
	"chicony-hp-wireless-keyboard-mouse-kit",
	"chicony-hp-wireless-keyboard-mouse-kit-consumer-control",
	"chicony-hp-wireless-keyboard-mouse-kit-1",
}
local KB_LOGI_WIRED = {
	"logitech-mechanical-keyboard-logitech-mechanical-keyboard",
	"logitech-mechanical-keyboard-logitech-mechanical-keyboard-keyboard",
}
-- HyprLab / IdeaPad built-in (main AT keyboard + vendor extra buttons)
local KB_LAPTOP = {
	"at-translated-set-2-keyboard",
	"ideapad-extra-buttons",
	"sof-hda-dsp-headphone",
	"video-bus",
}
local MOUSE_LOGI_WIRELESS = {
	"logitech-wireless-mouse-1",
	"logitech-usb-receiver-mouse",
}

local function dev_bind(keys, dispatcher, devices, extra)
	local opts = {
		locked = true,
		device = { inclusive = true, list = devices },
	}
	if extra then
		for k, v in pairs(extra) do
			opts[k] = v
		end
	end
	hl.bind(keys, dispatcher, opts)
end

-- ── HyprLab laptop (IdeaPad) ─────────────────────────────────────────────────
-- F1 mute · F2 vol- · F3 vol+ · F4 mic mute (under consideration)
-- F5 bright- · F6 bright+ · F7 displays · F8 airplane
-- F9 settings · F10 lock · F11 apps · F12 calc
-- Insert clipboard · Print screenshot rofi · Delete stays native (typing)
dev_bind("F1",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle"),       KB_LAPTOP) -- #media #laptop Mute
dev_bind("F2",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --dec"),          KB_LAPTOP, { repeating = true }) -- #media #laptop Volume down
dev_bind("F3",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --inc"),          KB_LAPTOP, { repeating = true }) -- #media #laptop Volume up
-- F4 mic mute — under consideration (bound; remove if it fights firmware)
dev_bind("F4",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle-mic"),   KB_LAPTOP) -- #media #laptop #wip Mute mic
dev_bind("F5",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --dec"),      KB_LAPTOP, { repeating = true }) -- #display #laptop Brightness down
dev_bind("F6",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --inc"),      KB_LAPTOP, { repeating = true }) -- #display #laptop Brightness up
dev_bind("F7",  hl.dsp.exec_cmd(SCRIPTS .. "/monitor-rofi.sh"),          KB_LAPTOP) -- #display #laptop Display layouts
dev_bind("F8",  hl.dsp.exec_cmd(SCRIPTS .. "/airplane-mode.sh"),         KB_LAPTOP) -- #network #laptop Airplane mode
dev_bind("F9",  hl.dsp.exec_cmd(SCRIPTS .. "/hyprgruv-settings.sh"),     KB_LAPTOP) -- #settings #laptop HyprGruv settings
dev_bind("F10", hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf"), KB_LAPTOP) -- #session #laptop Lock
dev_bind("F11", hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),             KB_LAPTOP) -- #launcher #laptop Applications
dev_bind("F12", hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"),             KB_LAPTOP) -- #calc #laptop Calculator

dev_bind("INSERT", hl.dsp.exec_cmd(SCRIPTS .. "/cliphist.sh"),           KB_LAPTOP) -- #clipboard #laptop Clipboard history
dev_bind("PRINT",  hl.dsp.exec_cmd(SCRIPTS .. "/hyprshot.sh"),           KB_LAPTOP) -- #screenshot #laptop Screenshot menu
-- DELETE intentionally unbound on laptop so editors keep native delete

-- XF86 keys (what many IdeaPads emit without holding FN). Same actions as F-row above
-- so media-default FN layout still hits Hypr binds instead of doing nothing.
dev_bind("XF86AudioMute",         hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle"),     KB_LAPTOP) -- #media #laptop
dev_bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --dec"),        KB_LAPTOP, { repeating = true })
dev_bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --inc"),        KB_LAPTOP, { repeating = true })
dev_bind("XF86AudioMicMute",      hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle-mic"), KB_LAPTOP) -- #wip
dev_bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --dec"),    KB_LAPTOP, { repeating = true })
dev_bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --inc"),    KB_LAPTOP, { repeating = true })
dev_bind("XF86Display",           hl.dsp.exec_cmd(SCRIPTS .. "/monitor-rofi.sh"),        KB_LAPTOP)
dev_bind("XF86WLAN",              hl.dsp.exec_cmd(SCRIPTS .. "/airplane-mode.sh"),       KB_LAPTOP)
dev_bind("XF86RFKill",            hl.dsp.exec_cmd(SCRIPTS .. "/airplane-mode.sh"),       KB_LAPTOP)
dev_bind("XF86Tools",             hl.dsp.exec_cmd(SCRIPTS .. "/hyprgruv-settings.sh"),   KB_LAPTOP)
dev_bind("XF86Launch1",           hl.dsp.exec_cmd(SCRIPTS .. "/hyprgruv-settings.sh"),   KB_LAPTOP)
dev_bind("XF86Calculator",        hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"),           KB_LAPTOP)
dev_bind("XF86Explorer",          hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),           KB_LAPTOP)
dev_bind("XF86Search",            hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),           KB_LAPTOP)
dev_bind("XF86Favorites",         hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),           KB_LAPTOP)

-- Keyboard backlight (IdeaPad: platform::kbd_backlight, levels 0–2)
dev_bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d platform::kbd_backlight set +1"), KB_LAPTOP) -- #laptop KB light up
dev_bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d platform::kbd_backlight set 1-"), KB_LAPTOP) -- #laptop KB light down
-- Fallback if firmware sends no XF86 keys: Super+F8/F9 cycle keyboard light (laptop only)
dev_bind(mainMod .. " + F8", hl.dsp.exec_cmd("brightnessctl -d platform::kbd_backlight set 1-"), KB_LAPTOP) -- #laptop KB light down
dev_bind(mainMod .. " + F9", hl.dsp.exec_cmd("brightnessctl -d platform::kbd_backlight set +1"), KB_LAPTOP) -- #laptop KB light up

-- ── HP wireless (Chicony kit) ────────────────────────────────────────────────
-- F1 mute · F2 vol- · F3 vol+ · F4 prev · F5 pause · F6 next
-- F7 bright- · F8 bright+ · F9 search · F10 Mission Control · F11 audio · F12 settings
dev_bind("F1",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle"),     KB_HP) -- #media Mute
dev_bind("F2",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --dec"),        KB_HP, { repeating = true }) -- #media Volume down
dev_bind("F3",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --inc"),        KB_HP, { repeating = true }) -- #media Volume up
dev_bind("F4",  hl.dsp.exec_cmd("playerctl previous"),                 KB_HP) -- #media Previous track
dev_bind("F5",  hl.dsp.exec_cmd("playerctl play-pause"),               KB_HP) -- #media Play/Pause
dev_bind("F6",  hl.dsp.exec_cmd("playerctl next"),                     KB_HP) -- #media Next track
dev_bind("F7",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --dec"),    KB_HP, { repeating = true }) -- #display Brightness down
dev_bind("F8",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --inc"),    KB_HP, { repeating = true }) -- #display Brightness up
dev_bind("F9",  hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),           KB_HP) -- #launcher Search apps
dev_bind("F10", hl.dsp.exec_cmd(SCRIPTS .. "/mission-control.sh"),     KB_HP) -- #window Mission Control
dev_bind("F11", hl.dsp.exec_cmd("pavucontrol"),                        KB_HP) -- #audio Audio mixer
dev_bind("F12", hl.dsp.exec_cmd(SCRIPTS .. "/hyprgruv-settings.sh"),   KB_HP) -- #settings Hyprland / HyprGruv settings

-- ── Logitech wired mechanical ────────────────────────────────────────────────
-- F1 bright- · F2 bright+ · F3 search · F4 calc · F5 kew · F6 prev
-- F7 play/pause · F8 next · F9 mute · F10 vol- · F11 vol+ · F12 settings
dev_bind("F1",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --dec"),    KB_LOGI_WIRED, { repeating = true }) -- #display Brightness down
dev_bind("F2",  hl.dsp.exec_cmd(SCRIPTS .. "/brightness.sh --inc"),    KB_LOGI_WIRED, { repeating = true }) -- #display Brightness up
dev_bind("F3",  hl.dsp.exec_cmd(SCRIPTS .. "/rofi-full.sh"),           KB_LOGI_WIRED) -- #launcher Search apps
dev_bind("F4",  hl.dsp.exec_cmd(SCRIPTS .. "/rofi_calc.sh"),           KB_LOGI_WIRED) -- #calc Rofi calculator
dev_bind("F5",  hl.dsp.exec_cmd(SCRIPTS .. "/terminal.sh kew"),        KB_LOGI_WIRED) -- #music Open kew
dev_bind("F6",  hl.dsp.exec_cmd("playerctl previous"),                 KB_LOGI_WIRED) -- #media Previous track
dev_bind("F7",  hl.dsp.exec_cmd("playerctl play-pause"),               KB_LOGI_WIRED) -- #media Play/Pause
dev_bind("F8",  hl.dsp.exec_cmd("playerctl next"),                     KB_LOGI_WIRED) -- #media Next track
dev_bind("F9",  hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --toggle"),     KB_LOGI_WIRED) -- #media Mute
dev_bind("F10", hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --dec"),        KB_LOGI_WIRED, { repeating = true }) -- #media Volume down
dev_bind("F11", hl.dsp.exec_cmd(SCRIPTS .. "/volume.sh --inc"),        KB_LOGI_WIRED, { repeating = true }) -- #media Volume up
dev_bind("F12", hl.dsp.exec_cmd(SCRIPTS .. "/hyprgruv-settings.sh"),   KB_LOGI_WIRED) -- #settings Hyprland / HyprGruv settings

-- ── Logitech wireless mouse: press scroll wheel = screenshot ─────────────────
-- mouse:274 = MMB (scroll wheel click). Not mouse=true — that flag is for drag/resize.
hl.bind("mouse:274", hl.dsp.exec_cmd(SCRIPTS .. "/quickshot.sh"), {
	device = { inclusive = true, list = MOUSE_LOGI_WIRELESS },
}) -- #screenshot Middle-click (scroll wheel) region screenshot

-- Mission Control: conf/hymission.lua