-- conf/autostart.lua
-- Converted from conf/autostart.conf
-- Most exec-once become hl.on("hyprland.start", function() hl.exec_cmd(...) end)

local SCRIPTS = os.getenv("HOME") .. "/.config/hyprgruv/scripts"
local HYPRPM_RELOAD = SCRIPTS .. "/hyprpm-reload.sh"

local function reload_hyprpm()
    hl.exec_cmd(HYPRPM_RELOAD)
end

-- Hyprpm: every new Hyprland session (login) and after config reload
hl.on("hyprland.start", reload_hyprpm)
hl.on("config.reloaded", reload_hyprpm)

-- Run on every Hyprland start (use hl.on for the event)
hl.on("hyprland.start", function()
    -- Polkit (Hyprland-native agent)
    os.execute(SCRIPTS .. "/launch-hyprpolkitagent.sh >/dev/null 2>&1 &")

    -- Idle + bar
    hl.exec_cmd("hypridle & waybar")

    -- Clipboard history (images)
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cleanup
    hl.exec_cmd(SCRIPTS .. "/cleanup.sh")

    -- Restart wallpaper system cleanly on every start
    hl.exec_cmd("killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true")
    hl.exec_cmd("waypaper-engine daemon &")

    -- Restore wallpaper after monitors are ready
    hl.exec_cmd("sleep 2 && ~/.local/bin/waypaper --restore &")

    -- Cursor theme
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic-Gruvbox 24")

    -- Workspace monitor setup script
    hl.exec_cmd(SCRIPTS .. "/monitor-workspaces.sh")

    -- Auto-mount
    hl.exec_cmd("udiskie")

    -- SwayNC
    hl.exec_cmd(SCRIPTS .. "/notify-autostart.sh")

    -- The original also had a non-once exec here:
    -- hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- Non-once (run on every reload) items from original
hl.on("config.reloaded", function()
    hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- One-time things that were plain "exec" (not exec-once) in original main file
-- moved to main hyprland.lua
