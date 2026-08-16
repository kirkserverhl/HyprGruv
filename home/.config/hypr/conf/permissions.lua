-- conf/permissions.lua
-- Hyprland Android-like permission system (0.55+).
-- Wiki: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
--
-- Rules are NOT applied by hyprctl reload — restart Hyprland.
-- Matching is RE2 FullMatch (whole path). First matching rule wins.
-- Modes: allow | ask | deny
-- Unmatched requests fall back to the type default (see each section).

local user = os.getenv("USER") or os.getenv("LOGNAME") or "kirk"
local hyprpm_cache = "/var/cache/hyprpm/" .. user

-- Without this, every rule below is ignored.
hl.config({
	ecosystem = {
		enforce_permissions = true,
	},
})

-- Official 0.56 example uses positional args; table form is equivalent.
local function permit(binary, type, mode)
	hl.permission(binary, type, mode)
end

-- =============================================================================
-- plugin (default: ASK)
-- Load a .so into the compositor. Match the loader binary and/or the .so path.
-- Do not allow hyprctl globally: `hyprctl plugin load /tmp/evil.so` would work.
-- Super+R / bar-mode still work because hyprbars.so is allowlisted below.
-- =============================================================================

-- hyprbars. Match the .so path (not hyprctl): the plugin dialog has no
-- "always allow" — Allow is cached by hyprctl PID, which exits immediately.
-- Theme apply (`hyprctl reload`) and bar-mode (`hyprctl plugin load`) then
-- prompt again unless this rule matches. Live cache is still
-- hyprland-plugins/; hyprplug/ is the intended hyprpm pin.
permit(hyprpm_cache .. "/.*/hyprbars\\.so", "plugin", "allow")

-- hymission is a separate repo, already enabled in this session.
-- Leave this allow so login / hyprpm reload does not prompt for it.
permit(hyprpm_cache .. "/hymission/.*\\.so", "plugin", "allow")

-- hyprpm is the intended loader (autostart → hyprpm-reload.sh).
-- Any plugin you later `hyprpm enable` will also load without a prompt.
permit("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- Stricter option: comment the hyprpm line and keep only the .so allows.
-- New plugins then ASK (or DENY if you uncomment the catch-all).
-- permit(".*", "plugin", "deny")

-- =============================================================================
-- screencopy (default: ASK)
-- Direct Wayland capture (grim, hyprpicker, hyprlock screenshot bg, recorders).
-- Denied clients get a black frame + "permission denied".
-- Portal apps (browser/Discord share) go through xdg-desktop-portal-hyprland;
-- allowing the portal still shows the portal's own picker.
-- =============================================================================

-- Screenshots: hyprshot.sh / quickshot.sh shell out to grim.
permit("/usr/(bin|local/bin)/grim", "screencopy", "allow")

-- Color picker (Alt+P / Super+Alt+P).
permit("/usr/(bin|local/bin)/hyprpicker", "screencopy", "allow")

-- hyprlock background { path = screenshot } — without this, lock bg is black.
permit("/usr/(bin|local/bin)/hyprlock", "screencopy", "allow")

-- GPU Screen Recorder (Alt+Z overlay + CLI encoder).
permit("/usr/(bin|local/bin)/gpu-screen-recorder", "screencopy", "allow")
permit("/usr/(bin|local/bin)/gsr-cli", "screencopy", "allow")
permit("/usr/(bin|local/bin)/gsr-ui", "screencopy", "allow")
permit("/usr/(bin|local/bin)/gsr-wayland-bridge", "screencopy", "allow")

-- Trusted portal. Required for intentional share-screen via xdg-desktop-portal.
permit("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")

-- Hard-block every other direct capturer (OBS, wf-recorder, random scripts).
-- Portal sharing still works because xdph is allowlisted above.
-- Uncomment when you want "no" instead of "ask" for unknown apps:
-- permit(".*", "screencopy", "deny")

-- =============================================================================
-- cursorpos (default: ASK)
-- Cursor coordinates + cursor image via Wayland protocols (not the portal).
-- Leave unmatched = ASK. Allow a specific picker if a tool nags you:
-- permit("/usr/(bin|local/bin)/hyprpicker", "cursorpos", "allow")
-- =============================================================================

-- =============================================================================
-- input-capture (default: ASK)
-- Grab all keyboard / pointer / touch events (KVM, remote desktop, some overlays).
-- Leave unmatched = ASK. Example if you add a remote-desktop tool:
-- permit("/usr/(bin|local/bin)/wayvnc", "input-capture", "allow")
-- gsr-ui can grab keyboards for its own hotkeys. Prefer Hyprland Alt+Z +
-- "don't grab devices" in gsr-ui Settings; allow if you turn grab back on:
permit("/usr/(bin|local/bin)/gsr-ui", "input-capture", "allow")
permit("/usr/(bin|local/bin)/gsr-global-hotkeys", "input-capture", "allow")
-- =============================================================================

-- =============================================================================
-- keyboard (default: ALLOW)
-- New physical/virtual keyboards. Deny last to block rubber-ducky / unknown HIDs.
-- permit("my-keyboard-name-regex", "keyboard", "allow")
-- permit(".*", "keyboard", "deny")
-- =============================================================================
