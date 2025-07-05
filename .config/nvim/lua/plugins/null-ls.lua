return {
  "nvimtools/none-ls.nvim",
  config = function()
    local nonels = require("null-ls")
    nonels.setup({
      sources = {
        -- formatting tools
        nonels.builtins.formatting.stylua,
        nonels.builtins.formatting.black,
        nonels.builtins.formatting.isort,
        nonels.builtins.formatting.prettier,
        -- diagnostics tools
        nonels.builtins.diagnostics.eslint_d,
        nonels.builtins.diagnostics.luacheck,
        require("none-ls.diagnostics.eslint"),
      },
    })
    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
