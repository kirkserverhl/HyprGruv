-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#090f10",
    base01 = "#161d1d",  -- lighter bg, inactive borders
    base02 = "#1a2121",
    base03 = "#3f4949",
    base04 = "#bec8c9",
    base05 = "#dde4e3",
    base06 = "#2b3232",
    base07 = "#343a3b",
    base08 = "#ffb4ab",
    base09 = "#b5c7e9",
    base0A = "#b1cccd",
    base0B = "#80d4d8",
    base0C = "#364764",
    base0D = "#80d4d8",
    base0E = "#324b4c",
    base0F = "#458588",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "#1a2121",
  fg = "#dde4e3",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "#3f4949", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#3f4949", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#161d1d" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffb4ab" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#b5c7e9" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#80d4d8" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#364764" })

pcall(function() require("lualine").setup({}) end)