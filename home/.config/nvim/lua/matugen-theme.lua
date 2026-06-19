-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#0e0e13",
    base01 = "#1c1b20",  -- lighter bg, inactive borders
    base02 = "#201f25",
    base03 = "#47464f",
    base04 = "#c8c5d0",
    base05 = "#e5e1e9",
    base06 = "#313036",
    base07 = "#3a383e",
    base08 = "#ffb4ab",
    base09 = "#ebb8cf",
    base0A = "#c8c3dc",
    base0B = "#c6c0ff",
    base0C = "#613b4e",
    base0D = "#c6c0ff",
    base0E = "#474459",
    base0F = "#211c4f",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#201f25",
  fg = "#e5e1e9",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#47464f", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#47464f", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1c1b20" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffb4ab" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#ebb8cf" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#c6c0ff" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#613b4e" })

pcall(function() require("lualine").setup({}) end)