return {
  {
    "markdown-links.nvim",
    dir = vim.fn.stdpath("config"),
    name = "markdown-links",
    event = "VeryLazy",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("markdown_links", { clear = true }),
        pattern = { "markdown", "markdown.mdx" },
        callback = function(event)
          vim.keymap.set("n", "gx", function()
            require("markdown-links").open()
          end, {
            buffer = event.buf,
            desc = "Open link under cursor",
            silent = true,
          })
        end,
      })
    end,
  },
}