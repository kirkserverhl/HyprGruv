-- colors/init.lua
-- Dynamic color loader for Matugen + pywal + preset theme rainbow palettes

local M = {}

local function parse_colors_file(path)
    local colors = {}
    local f = io.open(path, "r")
    if not f then return colors end
    for line in f:lines() do
        local var, val = line:match("^%s*%$([%w_]+)%s*=%s*(.+)%s*$")
        if var and val then
            val = val:gsub("%s*#.*$", "")
            colors[var] = val
        end
    end
    f:close()
    return colors
end

local function parse_rainbow_palette_cache()
    local home = os.getenv("HOME")
    local path = home .. "/.cache/matugen/rainbow-palette.json"
    local f = io.open(path, "r")
    if not f then return {} end
    local raw = f:read("*a")
    f:close()

    local palette = {}
    local in_colors = false
    for line in raw:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed:match('^"colors"%s*:') or trimmed == '"colors": {' then
            in_colors = true
        elseif in_colors and trimmed == "}," or trimmed == "}" then
            break
        elseif in_colors then
            local key, val = trimmed:match('"([%w_]+)"%s*:%s*"(#[%x]+)"')
            if key and val then
                palette[key] = val
            end
        end
    end
    return palette
end

local function parse_starship_palette_file(path)
    local f = io.open(path, "r")
    if not f then return {} end

    local palette = {}
    local in_palette_section = false

    for line in f:lines() do
        local trimmed = line:match("^%s*(.-)%s*$")

        if trimmed:match("^%[palettes%.") then
            in_palette_section = true
        elseif in_palette_section and trimmed:match("^%[") then
            break
        elseif in_palette_section and trimmed ~= "" and not trimmed:match("^#") then
            local key, val = trimmed:match("^([%w_]+)%s*=%s*['\"]?([#%x]+)['\"]?")
            if key and val then
                if not val:match("^#") then val = "#" .. val end
                palette[key] = val
            end
        end
    end

    f:close()
    return palette
end

local function resolve_starship_palette()
    local home = os.getenv("HOME")

    local cached = parse_rainbow_palette_cache()
    if next(cached) ~= nil then
        return cached
    end

    local candidates = {
        home .. "/.config/starship/matugen-rainbow.toml",
        home .. "/.config/starship/gruvbox-rainbow.toml",
        home .. "/.config/starship.toml",
    }

    for _, path in ipairs(candidates) do
        local palette = parse_starship_palette_file(path)
        if next(palette) ~= nil then
            return palette
        end
    end

    return {}
end

function M.load()
    local home = os.getenv("HOME")
    local colors = {}

    local static = parse_colors_file(home .. "/.config/hypr/colors/colors.conf")
    local gruv = parse_colors_file(home .. "/.config/hypr/colors/custom/gruvbox-dark.conf")
    for k, v in pairs(gruv) do colors[k] = v end
    for k, v in pairs(static) do colors[k] = v end

    local wal = parse_colors_file(home .. "/.cache/wal/colors-hyprland.conf")
    for k, v in pairs(wal) do colors[k] = v end

    local matugen = parse_colors_file(home .. "/.config/hypr/colors/custom/matugen.conf")

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

    local starship = resolve_starship_palette()
    colors.starship = starship

    colors.bg   = normalize_color(colors.bg or colors.background, "rgb(131313)")
    colors.fg   = normalize_color(colors.fg or colors.on_background, "rgb(e5e1e9)")
    colors.text = normalize_color(colors.text or colors.on_surface, colors.fg or "rgb(e5e1e9)")

    colors.source_color = colors.source_color or "rgba(4285f4ff)"
    colors.tertiary     = colors.tertiary or "rgba(e2e2e2ff)"

    colors.bg1 = normalize_color(colors.bg1 or colors.surface_container, "rgb(201f25)")
    colors.fg  = normalize_color(colors.fg  or colors.on_background,     "rgb(e5e1e9)")

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

    -- Hyprbars: close → orange | minimize → yellow | maximize → blue
    colors.hyprbar_close    = starship_color("color_orange", colors.primary or colors.base09, "rgb(d65d0e)")
    colors.hyprbar_minimize = starship_color("color_yellow", colors.tertiary or colors.base0A, "rgb(d79921)")
    colors.hyprbar_maximize = starship_color("color_blue",   colors.primary_container or colors.base0E, "rgb(458588)")

    colors.hyprbar_close_fg    = starship_color("color_on_orange", colors.on_primary or colors.on_background, "rgb(fbf1c7)")
    colors.hyprbar_minimize_fg = starship_color("color_on_yellow", colors.on_tertiary or colors.on_background, "rgb(fbf1c7)")
    colors.hyprbar_maximize_fg = starship_color("color_fg0",       colors.on_surface or colors.on_background, "rgb(fbf1c7)")

    return colors
end

return M