-- Matugen → Neovim theme (mini.base16)
-- Base16 slots mapped from Material You roles.

local ok, base16 = pcall(require, "mini.base16")
if not ok then
  vim.notify("mini.base16 not installed — matugen theme skipped", vim.log.levels.WARN)
  return
end

base16.setup({
  palette = {
    base00 = "{{colors.surface_container_lowest.dark.hex}}",
    base01 = "{{colors.surface_container_low.dark.hex}}",  -- lighter bg, inactive borders
    base02 = "{{colors.surface_container.dark.hex}}",
    base03 = "{{colors.outline_variant.dark.hex}}",
    base04 = "{{colors.on_surface_variant.dark.hex}}",
    base05 = "{{colors.on_surface.dark.hex}}",
    base06 = "{{colors.inverse_on_surface.dark.hex}}",
    base07 = "{{colors.surface_bright.dark.hex}}",
    base08 = "{{colors.error.dark.hex}}",
    base09 = "{{colors.tertiary.dark.hex}}",
    base0A = "{{colors.secondary.dark.hex}}",
    base0B = "{{colors.primary.dark.hex}}",
    base0C = "{{colors.tertiary_container.dark.hex}}",
    base0D = "{{colors.primary.dark.hex}}",
    base0E = "{{colors.secondary_container.dark.hex}}",
    base0F = "{{colors.source_color.dark.hex}}",
  },
  use_cterm = false,
  plugins = { default = true },
})

vim.api.nvim_set_hl(0, "Visual", {
  bg = "{{colors.surface_container.dark.hex}}",
  fg = "{{colors.on_surface.dark.hex}}",
})
-- base03 — muted text / comments
vim.api.nvim_set_hl(0, "Comment", { fg = "{{colors.outline_variant.dark.hex}}", italic = true })
vim.api.nvim_set_hl(0, "@comment", { fg = "{{colors.outline_variant.dark.hex}}", italic = true })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "{{colors.surface_container_low.dark.hex}}" })

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "{{colors.error.dark.hex}}" })
vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "{{colors.tertiary.dark.hex}}" })
vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "{{colors.primary.dark.hex}}" })
vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "{{colors.tertiary_container.dark.hex}}" })

pcall(function() require("lualine").setup({}) end)