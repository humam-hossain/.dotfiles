return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    terminal = {
      enabled = true,
      win = {
        style = "terminal",
        height = 0.3,
        width = 0.8,
        border = "rounded",
        title = " Terminal",
        title_pos = "center",
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
    local terminal = snacks.terminal

    snacks.setup(opts)

    -- Toggle terminal (default shell)
    vim.keymap.set({ "n", "t" }, "<C-\\>", function()
      terminal.toggle()
      vim.cmd("stopinsert")
    end, { desc = "Toggle terminal" })

    vim.keymap.set("n", "<leader>tt", function()
      terminal.toggle()
    end, { desc = "Toggle terminal" })

    vim.keymap.set("n", "<leader>tf", function()
      terminal.open(nil, { win = { position = "float" } })
      vim.cmd("stopinsert")
    end, { desc = "Open floating terminal" })

    vim.keymap.set("n", "<leader>tr", function()
      terminal.open(nil, { win = { position = "right" } })
    end, { desc = "Open terminal right" })

    vim.keymap.set("n", "<leader>tl", function()
      terminal.open(nil, { win = { position = "left" } })
    end, { desc = "Open terminal left" })

    vim.keymap.set("n", "<leader>tb", function()
      terminal.open(nil, { win = { position = "bottom" } })
    end, { desc = "Open terminal bottom" })

    vim.keymap.set("n", "<leader>ts", function()
      terminal.open(nil, { win = { position = "top" } })
    end, { desc = "Open terminal top" })

    -- Terminal management
    vim.keymap.set("n", "<leader>tn", function()
      terminal.open()
    end, { desc = "New terminal" })

    -- Kill current terminal
    vim.keymap.set("n", "<leader>tk", function()
      local t = terminal.get() -- get current (won’t create)
      if t then
        t:close()
      end
    end, { desc = "Kill terminal" })

    vim.keymap.set("n", "<leader>t]", function()
      terminal.next()
    end, { desc = "Next terminal" })

    vim.keymap.set("n", "<leader>t[", function()
      terminal.prev()
    end, { desc = "Previous terminal" })

    -- Open terminal with specific commands
    vim.keymap.set("n", "<leader>tg", function()
      terminal.open("lazygit", {
        win = { position = "float" },
        interactive = false,
      })
    end, { desc = "Open lazygit" })

    vim.keymap.set("n", "<leader>th", function()
      terminal.open("htop", {
        win = { position = "float" },
        interactive = false,
      })
    end, { desc = "Open htop" })

    vim.keymap.set("n", "<leader>tp", function()
      terminal.open("python3", {
        win = { position = "bottom" },
        interactive = true,
      })
    end, { desc = "Open Python REPL" })

    vim.keymap.set("n", "<leader>tz", function()
      terminal.open("zsh", {
        win = { position = "bottom" },
        interactive = true,
      })
    end, { desc = "Open Zsh" })

    -- Terminal mode keymaps (when inside terminal)
    vim.keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })

    -- Window navigation from terminal (using Alt key to avoid conflicts)
    vim.keymap.set("t", "<A-h>", "<C-\\><C-n><C-w>h", { desc = "Move to left window" })
    vim.keymap.set("t", "<A-j>", "<C-\\><C-n><C-w>j", { desc = "Move to bottom window" })
    vim.keymap.set("t", "<A-k>", "<C-\\><C-n><C-w>k", { desc = "Move to top window" })
    vim.keymap.set("t", "<A-l>", "<C-\\><C-n><C-w>l", { desc = "Move to right window" }) -- Auto-enter insert mode when entering terminal

    -- Highlight groups for better terminal appearance
    vim.api.nvim_set_hl(0, "SnacksTerminalNormal", { bg = "#1e1e2e" })
    vim.api.nvim_set_hl(0, "SnacksTerminalBorder", { fg = "#89b4fa" })
  end,
}
