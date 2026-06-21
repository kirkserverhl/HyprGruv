-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#14181b",
    base01 = "#1e2429",  -- lighter bg, inactive borders
    base02 = "#283036",
    base03 = "#657366",
    base04 = "#859289",
    base05 = "#d3c6aa",
    base06 = "#283036",
    base07 = "#3c4851",
    base08 = "#e67e80",
    base09 = "#d699b6",
    base0A = "#dbbc7f",
    base0B = "#a7c080",
    base0C = "#83c092",
    base0D = "#a7c080",
    base0E = "#7fbbb3",
    base0F = "#e69875",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#283036",
  fg = "#d3c6aa",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#657366", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#657366", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1e2429" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#e67e80" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#d699b6" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#a7c080" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#83c092" })

pcall(function() require("lualine").setup({}) end)