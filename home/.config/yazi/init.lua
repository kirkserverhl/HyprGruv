-- Show dotfiles by default (show_hidden = true in yazi.toml).
-- Re-apply after cd in case tab state was toggled off in a prior session.
if rt.mgr.show_hidden then
	local function show_dotfiles()
		if not cx.active.pref.show_hidden then
			ya.emit("hidden", { "show" })
		end
	end

	ps.sub("cd", show_dotfiles)
	ya.emit("hidden", { "show" })
end