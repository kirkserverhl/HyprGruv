-- Official colorschemes Super+W can switch via matugen-theme.lua.
-- Catppuccin Mocha is the Catppuccin slot; gruvbox covers Gruvbox / Coast / Warm Stone.

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
  },
}
