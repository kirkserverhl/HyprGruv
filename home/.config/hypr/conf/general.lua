-- conf/general.lua
-- Merged: conf/window.conf + conf/layout.conf + relevant parts of conf/misc.conf

-- Colors are loaded fresh on every invocation (see apply_borders below)
-- so that matugen-triggered `hyprctl reload` updates the borders.

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 8,
		border_size = 3,

		layout = "dwindle",
		resize_on_border = true,
	},

	dwindle = {
		preserve_split = true,
		-- force_split = 0,
	},

	master = {
		-- new_status = "master",   -- commented in original for compatibility
	},

	-- Scrolling / column layout (built-in since Hyprland 0.54+)
	-- Optional research mode: infinite horizontal columns (niri-like).
	-- Toggle with Alt+J — see conf/keybinds.lua.
	-- Wiki: https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
	scrolling = {
		-- Default column ~half screen so two research panes sit side by side.
		column_width = 0.5,
		-- Solo window fills the monitor (feels like dwindle until you open more).
		fullscreen_on_one_column = true,
		follow_focus = true,
		-- 0 = center column, 1 = fit into view (better for research panes)
		focus_fit_method = 1,
		-- Cycle with Alt+, / Alt+.  (colresize ±conf)
		explicit_column_widths = "0.4,0.5,0.67,0.8,1.0",
		wrap_focus = true,
		wrap_swapcol = true,
		direction = "right",
	},

	-- Binds related (from layout.conf)
	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
		-- Super+arrow / Super+hjkl: if no window in that direction, jump to
		-- the next monitor. Needs the outputs flush (no pixel gap).
		window_direction_monitor_fallback = true,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		initial_workspace_tracking = 1,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		swallow_regex = "^(Alacritty|kitty|footclient|brave|google-chrome|firefox)$",
		force_default_wallpaper = 0, -- 0 disables built-in anime wallpapers (use your own via waypaper/awww)
		mouse_move_enables_dpms = true,
	},

	debug = {
		vfr = false, -- sync to monitor refresh; reduces tearing
	},

	ecosystem = {
		no_update_news = true, -- was ecosystem:no_update_news
		no_donation_nag = true,
		-- Rules live in conf/permissions.lua. Restart Hyprland to apply.
		enforce_permissions = true,
	},

	xwayland = {
		force_zero_scaling = true,
	},
})

-- Dynamic border colors (matugen aware).
-- Borders must be re-applied on config.reloaded because the initial hl.config
-- above no longer bakes in colors at module parse time.
local function apply_borders()
	local colors = require("colors.init").load()
	-- Active = Super+W source/primary. Inactive = theme secondary (base0E), not grey.
	hl.config({
		general = {
			col = {
				active_border = colors.source_color
					or colors.primary
					or "rgba(d65d0eee)",
				inactive_border = colors.inactive_border
					or colors.secondary
					or colors.base0E
					or colors.base0C
					or colors.tertiary
					or "rgba(458588aa)",
			},
		},
	})
end


hl.on("hyprland.start", apply_borders)
hl.on("config.reloaded", apply_borders)
