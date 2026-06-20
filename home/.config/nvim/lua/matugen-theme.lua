-- Preset theme: gruvbox-dark — static palette (not Material You)

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — preset theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "#101213",
    base01 = "#59636e",
    base02 = "#59636e",
    base03 = "#59636e",
    base04 = "#a19a3b",
    base05 = "#c3c3c4",
    base06 = "#c3c3c4",
    base07 = "#c3c3c4",
    base08 = "#719055",
    base09 = "#719055",
    base0A = "#a19a3b",
    base0B = "#689467",
    base0C = "#dac99f",
    base0D = "#458487",
    base0E = "#beb290",
    base0F = "#458487",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", { bg = "#59636e", fg = "#c3c3c4" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#59636e", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "#59636e", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#59636e" })
vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#719055" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#a19a3b" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#458487" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#dac99f" })
