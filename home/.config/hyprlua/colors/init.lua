-- colors/init.lua
-- Dynamic color loader for Matugen + pywal + fallback
-- Loads from the same sources as the original .conf setup

local M = {}

-- Try to parse a hyprland colors file ( $var = rgba(....) or rgb(...) lines )
local function parse_colors_file(path)
    local colors = {}
    local f = io.open(path, "r")
    if not f then return colors end
    for line in f:lines() do
        -- $var = rgba(....) or rgb(...)
        local var, val = line:match("^%s*%$([%w_]+)%s*=%s*(.+)%s*$")
        if var and val then
            -- strip trailing comments
            val = val:gsub("%s*#.*$", "")
            colors[var] = val
        end
    end
    f:close()
    return colors
end

function M.load()
    local home = os.getenv("HOME")
    local colors = {}

    -- 1. Static fallback (gruvbox etc)
    local static = parse_colors_file(home .. "/.config/hypr/colors/colors.conf")
    -- the colors.conf itself sources custom/gruvbox-dark.conf, we parse the target too for robustness
    local gruv = parse_colors_file(home .. "/.config/hypr/colors/custom/gruvbox-dark.conf")
    for k, v in pairs(gruv) do colors[k] = v end
    for k, v in pairs(static) do colors[k] = v end

    -- 2. pywal cache (if present)
    local wal = parse_colors_file(home .. "/.cache/wal/colors-hyprland.conf")
    for k, v in pairs(wal) do colors[k] = v end

    -- 3. Matugen dynamic (highest priority, as in original)
    local matugen = parse_colors_file(home .. "/.config/hypr/colors/custom/matugen.conf")
    for k, v in pairs(matugen) do colors[k] = v end

    -- Provide common aliases used in the old config
    colors.bg   = colors.bg or colors.background or "rgb(131313ff)"
    colors.fg   = colors.fg or colors.on_background or "rgb(e2e2e2ff)"
    colors.text = colors.text or colors.on_surface or colors.fg

    -- Hyprland border variables used in window.conf
    colors.source_color = colors.source_color or "rgba(4285f4ff)"
    colors.tertiary     = colors.tertiary or "rgba(e2e2e2ff)"

    -- Plugin colors often referenced (with matugen fallbacks)
    colors.bg1 = colors.bg1 or colors.surface_container or "rgb(141414)"
    colors.fg  = colors.fg  or colors.on_background     or "rgb(e2e2e2ff)"

    return colors
end

return M
