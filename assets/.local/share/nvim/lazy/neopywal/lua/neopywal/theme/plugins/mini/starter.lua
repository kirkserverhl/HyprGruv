local M = {}

function M.get()
    return {
        MiniStarterCurrent = { link = "CursorLine" },
        MiniStarterHeader = { fg = C.color4, styles = { "bold" } },
        MiniStarterFooter = { fg = C.color5, styles = { "bold" } },
        MiniStarterInactive = { fg = C.comment },
        MiniStarterItem = { link = "Normal" },
        MiniStarterItemBullet = { fg = C.delimiter },
        MiniStarterItemPrefix = { fg = C.foreground, styles = { "bold" } },
        MiniStarterSection = { fg = C.color6, styles = { "bold" } },
        MiniStarterQuery = { fg = C.color1 },
    }
end

return M
