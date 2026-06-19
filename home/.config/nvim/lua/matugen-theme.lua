-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#0c0e13",
    base01 = "#191c20",  -- lighter bg, inactive borders
    base02 = "#1d2024",
    base03 = "#43474e",
    base04 = "#c4c6cf",
    base05 = "#e1e2e9",
    base06 = "#2e3035",
    base07 = "#37393e",
    base08 = "#ffb4ab",
    base09 = "#dbbce1",
    base0A = "#bdc7dc",
    base0B = "#a8c8ff",
    base0C = "#563e5d",
    base0D = "#a8c8ff",
    base0E = "#3e4758",
    base0F = "#89b4fa",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#1d2024",
  fg = "#e1e2e9",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#43474e", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#43474e", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#191c20" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffb4ab" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#dbbce1" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#a8c8ff" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#563e5d" })

pcall(function() require("lualine").setup({}) end)