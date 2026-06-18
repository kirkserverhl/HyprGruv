-- conf/scripts_path.lua
-- Prefer stowed ~/.config/hyprgruv/scripts; fall back to the repo checkout.

local M = {}

local function script_dir_ready(dir)
    local f = io.open(dir .. "/terminal.sh", "r")
    if f then
        f:close()
        return true
    end
    return false
end

function M.get()
    local home = os.getenv("HOME") or ""
    local deployed = home .. "/.config/hyprgruv/scripts"
    local repo = home .. "/.hyprgruv/home/.config/hyprgruv/scripts"

    if script_dir_ready(deployed) then
        return deployed
    end
    if script_dir_ready(repo) then
        return repo
    end
    return deployed
end

return M