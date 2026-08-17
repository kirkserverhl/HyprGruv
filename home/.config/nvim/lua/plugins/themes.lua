-- Official colorschemes Super+W can switch via matugen-theme.lua.
-- Catppuccin Mocha / Gruvbox / Everforest / Nord. Personal dipc themes
-- and noir still fall back to mini.base16 from the slot palette.

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
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("everforest").setup({
        -- Match official kitty everforest-dark-hard + swaync custom CSS.
        background = "hard",
      })
    end,
  },
  {
    "gbprod/nord.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
