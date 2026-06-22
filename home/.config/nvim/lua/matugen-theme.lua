-- Preset theme: nord-darker — static palette (not Material You)

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — preset theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#2e3440",
    base01 = "#3b4252",
    base02 = "#434c5e",
    base03 = "#e4e9ef",
    base04 = "#bfc5cd",
    base05 = "#d8dee9",
    base06 = "#434c5e",
    base07 = "#5f6c84",
    base08 = "#bf616a",
    base09 = "#b48ead",
    base0A = "#ebcb8b",
    base0B = "#a3be8c",
    base0C = "#8fbcbb",
    base0D = "#5e81ac",
    base0E = "#5e81ac",
    base0F = "#d08770",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", { bg = "#434c5e", fg = "#d8dee9" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#e4e9ef", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#e4e9ef", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3b4252" })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#bf616a" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#ebcb8b" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#5e81ac" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#8fbcbb" })

pcall(function() require("lualine").setup() end)
