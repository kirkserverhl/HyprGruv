-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#0b0e13",
    base01 = "#191c20",  -- lighter bg, inactive borders
    base02 = "#1d2024",
    base03 = "#43474e",
    base04 = "#c3c6cf",
    base05 = "#e1e2e8",
    base06 = "#2e3135",
    base07 = "#36393e",
    base08 = "#ffb4ab",
    base09 = "#d7bde4",
    base0A = "#bbc7db",
    base0B = "#a1c9fd",
    base0C = "#533f5f",
    base0D = "#a1c9fd",
    base0E = "#3c4858",
    base0F = "#5e81ac",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#1d2024",
  fg = "#e1e2e8",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#43474e", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#43474e", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#191c20" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffb4ab" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#d7bde4" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#a1c9fd" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#533f5f" })

pcall(function() require("lualine").setup({}) end)