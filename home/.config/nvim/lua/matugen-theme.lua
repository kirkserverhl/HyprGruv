-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#11111b",
    base01 = "#181825",  -- lighter bg, inactive borders
    base02 = "#1e1e2e",
    base03 = "#7f849c",
    base04 = "#6c7086",
    base05 = "#cdd6f4",
    base06 = "#1e1e2e",
    base07 = "#45475a",
    base08 = "#f38ba8",
    base09 = "#cba6f7",
    base0A = "#f9e2af",
    base0B = "#a6e3a1",
    base0C = "#94e2d5",
    base0D = "#a6e3a1",
    base0E = "#89b4fa",
    base0F = "#fab387",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#1e1e2e",
  fg = "#cdd6f4",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#7f849c", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#7f849c", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#181825" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#f38ba8" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#cba6f7" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#a6e3a1" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#94e2d5" })

pcall(function() require("lualine").setup({}) end)