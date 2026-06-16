-- conf/general.lua
-- Merged: conf/window.conf + conf/layout.conf + relevant parts of conf/misc.conf

local colors = require("colors.init").load()

hl.config({
	general = {
		gaps_in = 10,
		gaps_out = 5,
		border_size = 3,

		-- Colors come from dynamic loader (matugen > wal > gruvbox)
		col = {
			active_border = colors.source_color or "rgba(33ccffee) rgba(00ff99ee) 45deg",
			inactive_border = colors.tertiary or "rgba(595959aa)",
		},

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

	-- Scrolling layout (if you use it)
	scrolling = {
		column_width = 0.6,
		fullscreen_on_one_column = true,
		follow_focus = true,
		focus_fit_method = 0,
		explicit_column_widths = "0.5,0.67,0.8,1.0",
	},

	-- Binds related (from layout.conf)
	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		initial_workspace_tracking = 1,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		swallow_regex = "^(Alacritty|kitty|footclient|brave-browser)$",
		force_default_wallpaper = 0, -- 0 disables built-in anime wallpapers (use your own via waypaper/awww)
		mouse_move_enables_dpms = true,
	},

	ecosystem = {
		no_update_news = true, -- was ecosystem:no_update_news
		no_donation_nag = true,
	},

	xwayland = {
		force_zero_scaling = true,
	},
})
