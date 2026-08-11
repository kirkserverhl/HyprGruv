-- conf/input.lua
-- Touchpad defaults come from apply-machine-profile.sh (settings/*).

local settings = require("conf.settings")
local is_laptop = settings.is_laptop()

-- Classic scroll by default (false). Natural/inverse is opt-in via settings/natural_scroll.sh
-- so terminals + trackpads feel consistent on laptop deploys.
local natural = settings.read_bool("natural_scroll", false)
local tap = settings.read_bool("touchpad_tap", is_laptop)
local dwt = settings.read_bool("touchpad_dwt", is_laptop)
local scroll_factor = settings.read_number("touchpad_scroll_factor", is_laptop and 0.6 or 1.0)

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		-- caps:escape = Caps sends Escape (vim-friendly) without Escape toggling Caps Lock.
		-- swapescape caused Caps to flip when Escape was sent (mission control, dialogs, etc.).
		kb_options = "caps:escape",
		numlock_by_default = true,
		follow_mouse = 1,
		mouse_refocus = false,
		sensitivity = 0.1,

		touchpad = {
			natural_scroll = natural,
			scroll_factor = scroll_factor,
			tap_to_click = tap,
			disable_while_typing = dwt,
			-- Two-finger right-click; better for most laptop pads than clickfinger
			clickfinger_behavior = false,
		},
	},
})

-- G502 side buttons mapped to keys/macros in Piper are emitted on this HID
-- "keyboard" interface. enabled=false made Piper look correct while clicks did
-- nothing. Leave it enabled so macros work (no-op if device absent).
--
-- Tradeoff: this interface has its own Caps Lock LED state and can occasionally
-- flip Caps when focus follows the mouse. Prefer empty kb_options here over
-- disabling the device entirely.
hl.device({
	name = "logitech-g502-hero-gaming-mouse-keyboard",
	enabled = true,
	kb_options = "",
})
