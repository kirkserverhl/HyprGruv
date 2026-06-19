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

-- Parse the starship matugen-rainbow.toml palette so hyprbars (and other UI elements)
-- can directly reference the exact same color design/structure used by Starship.
local function parse_starship_matugen_palette()
    local home = os.getenv("HOME")
    local path = home .. "/.config/starship/matugen-rainbow.toml"
    local f = io.open(path, "r")
    if not f then return {} end

    local palette = {}
    local in_matugen_section = false

    for line in f:lines() do
        local trimmed = line:match("^%s*(.-)%s*$")

        if trimmed:match("^%[palettes%.matugen%]") then
            in_matugen_section = true
        elseif in_matugen_section and trimmed:match("^%[") then
            break
        elseif in_matugen_section and trimmed ~= "" and not trimmed:match("^#") then
            -- More tolerant match for key = "#hex" or key = '#hex'
            local key, val = trimmed:match("^([%w_]+)%s*=%s*['\"]?([#%x]+)['\"]?")
            if key and val then
                -- ensure it starts with #
                if not val:match("^#") then val = "#" .. val end
                palette[key] = val
            end
        end
    end

    f:close()
    return palette
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

    -- Resolve simple $var aliases that exist in the matugen.conf
    -- (e.g. $bg1 = $surface_container  and  $fg = $on_background)
    -- The naive parser captures the right-hand side literally.
    local function resolve_matugen_aliases(tbl, depth)
        depth = depth or 0
        if depth > 6 then return end
        for k, v in pairs(tbl) do
            if type(v) == "string" and v:match("^%$") then
                local ref = v:sub(2)
                if tbl[ref] then
                    tbl[k] = tbl[ref]
                    resolve_matugen_aliases(tbl, depth + 1)
                end
            end
        end
    end
    resolve_matugen_aliases(matugen)

    for k, v in pairs(matugen) do colors[k] = v end

    -- Helper to protect against unresolved $var strings or bad values
    local function normalize_color(c, fallback)
        if type(c) == "string" then
            if c:match("^%$") then
                return fallback
            end
            if c:match("^rgb") or c:match("^#") or c:match("^rgba") then
                return c
            end
        end
        return fallback
    end

    -- 4. Directly reference the Starship matugen rainbow palette (user's canonical design structure)
    -- This is the single source of truth for the "pattern" used across Starship segments,
    -- Waybar modules, and now hyprbars buttons.
    local starship = parse_starship_matugen_palette()
    colors.starship = starship   -- full access: colors.starship.color_red, color_yellow, color_green, etc.

    -- Provide common aliases used in the old config (with safety normalization)
    colors.bg   = normalize_color(colors.bg or colors.background, "rgb(131313)")
    colors.fg   = normalize_color(colors.fg or colors.on_background, "rgb(e5e1e9)")
    colors.text = normalize_color(colors.text or colors.on_surface, colors.fg or "rgb(e5e1e9)")

    -- Hyprland border variables used in window.conf
    colors.source_color = colors.source_color or "rgba(4285f4ff)"
    colors.tertiary     = colors.tertiary or "rgba(e2e2e2ff)"

    -- Plugin colors often referenced (with matugen fallbacks)
    -- Always prefer the underlying semantic keys (surface_container, on_background, etc.)
    colors.bg1 = normalize_color(colors.bg1 or colors.surface_container, "rgb(201f25)")
    colors.fg  = normalize_color(colors.fg  or colors.on_background,     "rgb(e5e1e9)")

    -- Hyprbars buttons — left-to-right matches starship / waybar rainbow chain:
    --   close (✕) → color_orange | float (⧉) → color_yellow | maximize (+) → color_aqua
    local function to_rgb(hex)
        if not hex then return nil end
        local h = hex:gsub("^#", "")
        return "rgb(" .. h .. ")"
    end

    local function starship_color(key, matugen_fallback, hard_fallback)
        if starship[key] then
            return normalize_color(to_rgb(starship[key]), hard_fallback)
        end
        return normalize_color(matugen_fallback, hard_fallback)
    end

    colors.hyprbar_close    = starship_color("color_orange", colors.base09 or colors.tertiary, "rgb(bdc5eb)")
    colors.hyprbar_minimize = starship_color("color_yellow", colors.yellow or colors.base0A, "rgb(b2cbd1)")
    colors.hyprbar_maximize = starship_color("color_aqua",   colors.primary_container or colors.base0C, "rgb(3d4565)")

    colors.hyprbar_close_fg    = starship_color("color_on_orange", colors.on_background or colors.bg, "rgb(090f11)")
    colors.hyprbar_minimize_fg = starship_color("color_on_yellow", colors.on_background or colors.bg, "rgb(090f11)")
    colors.hyprbar_maximize_fg = starship_color("color_on_aqua",   colors.on_background or colors.bg, "rgb(090f11)")

    return colors
end

return M
