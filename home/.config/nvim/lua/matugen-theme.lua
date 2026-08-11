-- Preset theme: noir — static palette (not Material You)

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — preset theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#121212",
    base01 = "#1e1e1e",
    base02 = "#2a2a2a",
    base03 = "#b9bdc2",
    base04 = "#888c94",
    base05 = "#e6e6e6",
    base06 = "#2a2a2a",
    base07 = "#444444",
    base08 = "#b0a0a5",
    base09 = "#a89cb0",
    base0A = "#b0ada0",
    base0B = "#a5b0a0",
    base0C = "#9cb0ad",
    base0D = "#888c94",
    base0E = "#9ca8b0",
    base0F = "#b0a8a0",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", { bg = "#2a2a2a", fg = "#e6e6e6" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#b9bdc2", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#b9bdc2", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1e1e1e" })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#b0a0a5" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#b0ada0" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#888c94" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#9cb0ad" })

pcall(function() require("lualine").setup() end)
