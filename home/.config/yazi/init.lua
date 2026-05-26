-- Force hidden files to be shown automatically when Yazi starts

local M = {}

function M:setup()
    -- Force hidden files on initial startup
    ya.manager_emit("hidden", { "show" })
end

function M:cd()
    -- Re-force hidden files whenever we change directory.
    -- This helps if any plugin tries to reset the state.
    ya.manager_emit("hidden", { "show" })
end

return M
