return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    terminal = {
      enabled = true,
      win = {
        style = "terminal",
        height = 0.4,
        width = 0.8,
        border = "rounded",
        title = " Terminal",
        title_pos = "right",
        -- Floating window specific options
        row = 0.3,
        col = 0.1,
      },
      -- terminal buffer options
      bo = {
        filetype = "snacks_terminal",
      },
      -- Terminal window local options
      wo = {
        winhighligh = "Normal:SnacksTerminalNormal,FloatBoarder:SnacksTerminalBorder",
      },
      -- keys specific to terminal mode
      keys = {
        -- Terminal navigation
        term_normal = "<C-\\><C-n>",

        -- Window navigation from terminal
        nav_h = "<C-n>",
        nav_j = "<C-j",
        nav_k = "<C-k>",
        nav_l = "<C-l>",

        -- Terminal management
        new = "<C-n>", -- Create new terminal
        kill = "<C-k>", -- Kill current terminal
        next = "<C-]>", -- Next terminal
        prev = "<C-[>", -- Previous terminal
      },
      -- Process Management
      process = {
        -- Auto-close terminal when process exits
        auto_close = true,
      },
      shell = "zsh",
    },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)

    -- Terminal keymaps
    local terminal = snacks.terminal

    -- Toggle Terminal
    vim.keymap.set({ "n", "t" }, "<leader>tt", function()
      terminal.toggle()
    end, { desc = "Toggle terminal" })
  end,
}
