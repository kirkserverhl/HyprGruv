-- conf/autostart.lua
-- Converted from conf/autostart.conf
-- Most exec-once become hl.on("hyprland.start", function() hl.exec_cmd(...) end)

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

-- Run on every Hyprland start / reload (use hl.on for the event)
hl.on("hyprland.start", function()
    -- Hyprpm (plugin manager)
    hl.exec_cmd("hyprpm reload")

    -- Hot corners (custom reliable implementation)
    hl.exec_cmd(SCRIPTS .. "/start-hyprcorners.sh")

    -- Polkit
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Idle + bar (or nothingless if that was the last choice via the toggle)
    hl.exec_cmd("hypridle & sh -c 's=${XDG_STATE_HOME:-$HOME/.local/state}/waybar/last_layout; if [ \"$(cat \"$s\" 2>/dev/null)\" = nothingless ]; then nothingless &; else ~/.config/waybar/scripts/launch.sh; fi'")

    -- Clipboard history (images)
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cleanup
    hl.exec_cmd(SCRIPTS .. "/cleanup.sh")

    -- Restart wallpaper system cleanly on every start
    hl.exec_cmd("killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true")
    hl.exec_cmd("waypaper-engine daemon &")

    -- Restore last wallpaper + re-apply matugen/colors on every login/start.
    -- Uses our script so we get both the image *and* the full post-processing (matugen etc.)
    -- without the interactive palette chooser popping on boot.
    hl.exec_cmd("sleep 1.5 && ~/.config/hypr/scripts/restore_wallpaper.sh &")

    -- Cursor theme
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic-Gruvbox 24")

    -- Workspace monitor setup script
    hl.exec_cmd(SCRIPTS .. "/monitor-workspaces.sh")

    -- Auto-mount
    hl.exec_cmd("udiskie")

    -- Dunst
    hl.exec_cmd("dunst")

    -- cava-bg: Wayland-native audio visualizer as desktop background (dynamic colors from wallpaper)
    hl.exec_cmd("cava-bg on")

    -- The original also had a non-once exec here:
    -- hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- Non-once (run on every reload) items from original
hl.on("config.reloaded", function()
    hl.exec_cmd("~/.config/hypr/hyprctl/hyprctl.sh")
end)

-- One-time things that were plain "exec" (not exec-once) in original main file
-- moved to main hyprland.lua
