-- Super+W official Neovim theme: gruvbox-dark → gruvbox
-- Do not replace with matugen mini.base16; that file is a Waypaper fallback.

vim.o.termguicolors = true
local ok = pcall(vim.cmd.colorscheme, "gruvbox")
if not ok then
  vim.notify("colorscheme gruvbox not found — install the plugin", vim.log.levels.WARN)
end
