-- conf/workspaces.lua
-- Converted from conf/workspaces.conf

-- Persistent workspaces (2 per monitor) using desc: for stability
hl.workspace_rule({ workspace = 1, monitor = "desc:LG Electronics LG FULL HD", persistent = true })
hl.workspace_rule({ workspace = 2, monitor = "desc:LG Electronics LG FULL HD", persistent = true })

hl.workspace_rule({ workspace = 3, monitor = "desc:LG Electronics 24CN65", persistent = true })
hl.workspace_rule({ workspace = 4, monitor = "desc:LG Electronics 24CN65", persistent = true })

hl.workspace_rule({ workspace = 5, monitor = "desc:LG Electronics LG Monitor", persistent = true })
hl.workspace_rule({ workspace = 6, monitor = "desc:LG Electronics LG Monitor", persistent = true })

hl.workspace_rule({ workspace = 7, monitor = "desc:LG Electronics LG TV", persistent = true })
hl.workspace_rule({ workspace = 8, monitor = "desc:LG Electronics LG TV", persistent = true })

-- Special workspace (scratchpad)
hl.workspace_rule({
    workspace = "special:scratchpad",
    persistent = true,
    on_created_empty = os.getenv("HOME") .. "/.config/hypr/scripts/terminal.sh"
})

-- "Smart gaps" examples (uncomment if desired)
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
