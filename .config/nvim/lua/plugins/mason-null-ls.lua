return {
  "jay-babu/mason-null-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "nvimtools/none-ls.nvim",
  },
  config = function()
    require("mason-null-ls").setup({
      ensure_installed = {
        -- Formatters
        "shfmt",              -- Bash
        "clang-format",       -- C/C++
        "google-java-format", -- Java
        "prettier",           -- JavaScript
        "stylua",             -- Lua
        "ruff",               -- Python (replaces black, isort, flake8)

        -- Linters
        "shellcheck", -- Bash
        "cppcheck",   -- C/C++
        "checkstyle", -- Java
        "eslint_d",   -- JavaScript
        "luacheck",   -- Lua
      },
      automatic_installation = true,
      handlers = {
        -- Default handler for all tools
        function() end, -- Let none-ls handle registration by default

        -- Optional: Custom handler for stylua (uncomment if needed)
        -- stylua = function(source_name, methods)
        --   require("null-ls").register({
        --     name = source_name,
        --     method = methods.FORMATTING,
        --     filetypes = { "lua" },
        --     generator = require("null-ls").builtins.formatting.stylua,
        --   })
        -- end,
      },
    })
  end,
}
