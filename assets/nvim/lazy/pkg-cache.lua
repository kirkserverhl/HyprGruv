return {version=12,pkgs={{source="lazy",name="noice.nvim",spec=function()
return {
  -- nui.nvim can be lazy loaded
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "folke/noice.nvim",
  },
}

end,dir="/home/kirk/.local/share/nvim/lazy/noice.nvim",file="lazy.lua",},{source="rockspec",name="nvim-dap-python",spec={"nvim-dap-python",specs={{"mfussenegger/nvim-dap",},},build=false,},dir="/home/kirk/.local/share/nvim/lazy/nvim-dap-python",file="nvim-dap-python-scm-1.rockspec",},{source="lazy",name="plenary.nvim",spec={"nvim-lua/plenary.nvim",lazy=true,},dir="/home/kirk/.local/share/nvim/lazy/plenary.nvim",file="community",},},}