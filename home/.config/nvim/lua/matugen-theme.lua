-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#100e07",
    base01 = "#1e1c13",  -- lighter bg, inactive borders
    base02 = "#222017",
    base03 = "#4a4739",
    base04 = "#ccc6b5",
    base05 = "#e8e2d4",
    base06 = "#333027",
    base07 = "#3c3930",
    base08 = "#ffb4ab",
    base09 = "#a8d0b5",
    base0A = "#d0c7a2",
    base0B = "#d8c76f",
    base0C = "#2a4e39",
    base0D = "#d8c76f",
    base0E = "#4d472b",
    base0F = "#857b4a",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#222017",
  fg = "#e8e2d4",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#4a4739", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#4a4739", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1e1c13" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffb4ab" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#a8d0b5" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#d8c76f" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#2a4e39" })

pcall(function() require("lualine").setup({}) end)