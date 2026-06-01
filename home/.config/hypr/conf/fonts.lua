-- fonts.lua
-- Centralized font loader for Hyprland Lua config (hyprland.lua)
-- Mirrors the pattern used by colors/init.lua
--
-- Usage from hyprland.lua or other modules:
--   local fonts = require("conf.fonts").load()
--   fonts.ui      --> "Agave Nerd Font Propo"
--   fonts.header  --> "HeavyData Nerd Font"
--   fonts.text    --> "ShureTechMono Nerd Font"

local M = {}

function M.load()
    local home = os.getenv("HOME") or ""
    local fonts = {
        text    = "ShureTechMono Nerd Font",
        ui      = "Agave Nerd Font Propo",
        header  = "HeavyData Nerd Font",
    }

    -- Try to load from the canonical shell file if it exists
    local fonts_sh = home .. "/.config/settings/fonts.sh"
    local f = io.open(fonts_sh, "r")
    if f then
        for line in f:lines() do
            -- Match: export FONT_TEXT="Something Nerd Font"
            local key, val = line:match('^export%s+FONT_(TEXT|UI|HEADER)%s*=%s*["\']([^"\']+)["\']')
            if key and val then
                if key == "TEXT" then
                    fonts.text = val
                elseif key == "UI" then
                    fonts.ui = val
                elseif key == "HEADER" then
                    fonts.header = val
                end
            end
        end
        f:close()
    end

    -- Convenience aliases
    fonts.text_family   = fonts.text
    fonts.ui_family     = fonts.ui
    fonts.header_family = fonts.header

    return fonts
end

return M
