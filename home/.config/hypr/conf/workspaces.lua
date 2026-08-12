-- conf/workspaces.lua
-- Desktop: 2 persistent workspaces per physical monitor (multi-monitor).
-- Laptop undocked: WS 1–2 on the built-in. Laptop + external: same 2-per-monitor
-- map as desktop (dock 1–2, panel 3–4) so Super+Tab cycles the pair on that screen.
-- Extra workspaces (5+) are created on demand (Super+N) and auto-drop when empty.

local settings = require("conf.settings")
local SCRIPTS = require("conf.scripts_path").get()
local is_laptop = settings.is_laptop()

if is_laptop then
	-- Work dock (serial-matched). Missing when undocked — Hyprland falls 1–2 back to eDP.
	hl.workspace_rule({
		workspace = 1,
		monitor = "desc:LG Electronics LG FULL HD 103MXTC4F409",
		persistent = true,
	})
	hl.workspace_rule({
		workspace = 2,
		monitor = "desc:LG Electronics LG FULL HD 103MXTC4F409",
		persistent = true,
	})
	-- Built-in always has its own pair so the panel is never a single workspace.
	hl.workspace_rule({
		workspace = 3,
		monitor = "desc:LG Display 0x061F",
		persistent = true,
	})
	hl.workspace_rule({
		workspace = 4,
		monitor = "desc:LG Display 0x061F",
		persistent = true,
	})
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
