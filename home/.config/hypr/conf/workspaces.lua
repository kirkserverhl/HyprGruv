-- conf/workspaces.lua
-- Desktop: 2 persistent workspaces per physical monitor (multi-monitor).
-- Laptop: only WS 1 (primary) + WS 2 (overflow) + special:scratchpad.
-- Extra workspaces (3+) are created on demand (Super+N) and auto-drop when empty.

local settings = require("conf.settings")
local SCRIPTS = require("conf.scripts_path").get()
local is_laptop = settings.is_laptop()

if is_laptop then
	-- Baseline: 1 main + 1 overflow. Waybar shows 1–2 + scratchpad icon.
	hl.workspace_rule({ workspace = 1, persistent = true })
	hl.workspace_rule({ workspace = 2, persistent = true })
else
	-- Persistent workspaces (2 per monitor) using desc: for stability
	hl.workspace_rule({ workspace = 1, monitor = "desc:LG Electronics LG FULL HD", persistent = true })
	hl.workspace_rule({ workspace = 2, monitor = "desc:LG Electronics LG FULL HD", persistent = true })

	hl.workspace_rule({ workspace = 3, monitor = "desc:LG Electronics 24CN65", persistent = true })
	hl.workspace_rule({ workspace = 4, monitor = "desc:LG Electronics 24CN65", persistent = true })

	hl.workspace_rule({ workspace = 5, monitor = "desc:LG Electronics LG Monitor", persistent = true })
	hl.workspace_rule({ workspace = 6, monitor = "desc:LG Electronics LG Monitor", persistent = true })

	hl.workspace_rule({ workspace = 7, monitor = "desc:LG Electronics LG TV", persistent = true })
	hl.workspace_rule({ workspace = 8, monitor = "desc:LG Electronics LG TV", persistent = true })
end

-- Special workspace (scratchpad) — all machines
hl.workspace_rule({
	workspace = "special:scratchpad",
	persistent = true,
	on_created_empty = SCRIPTS .. "/terminal.sh",
})
