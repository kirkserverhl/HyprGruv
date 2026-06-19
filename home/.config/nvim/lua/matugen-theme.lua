-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#0a0a0a",
    base01 = "#141414",  -- lighter bg, inactive borders
    base02 = "#1f1f1f",
    base03 = "#bcbcbc",
    base04 = "#888888",
    base05 = "#e6e6e6",
    base06 = "#1f1f1f",
    base07 = "#363636",
    base08 = "#555555",
    base09 = "#bbbbbb",
    base0A = "#bfc6dc",
    base0B = "#adc6ff",
    base0C = "#583e5b",
    base0D = "#adc6ff",
    base0E = "#3f4759",
    base0F = "#4285f4",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#1f1f1f",
  fg = "#e6e6e6",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#bcbcbc", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#bcbcbc", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#141414" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#555555" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#bbbbbb" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#adc6ff" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#583e5b" })

pcall(function() require("lualine").setup({}) end)