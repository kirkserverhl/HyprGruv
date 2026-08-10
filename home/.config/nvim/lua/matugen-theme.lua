-- Preset theme: gruvbox-dark — static palette (not Material You)

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — preset theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#1d2021",
    base01 = "#282828",
    base02 = "#3c3836",
    base03 = "#7c6f64",
    base04 = "#928374",
    base05 = "#ebdbb2",
    base06 = "#3c3836",
    base07 = "#665c54",
    base08 = "#cc241d",
    base09 = "#b16286",
    base0A = "#d79921",
    base0B = "#98971a",
    base0C = "#689d6a",
    base0D = "#d65d0e",
    base0E = "#458588",
    base0F = "#d65d0e",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", { bg = "#3c3836", fg = "#ebdbb2" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#7c6f64", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#7c6f64", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#282828" })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#cc241d" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#d79921" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#d65d0e" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#689d6a" })

pcall(function() require("lualine").setup() end)
