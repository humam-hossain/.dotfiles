return {
  "folke/noice.nvim",
  even = "VeryLazy",
  opts = {
    views = {
      cmdline_popup = {
        position = {
          row = "100%",
          col = "50%",
        },
        anchor = "SW",
        size = {
          width = 100,
          height = "auto",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = "67%",
          col = "50%",
        },
        size = {
          width = 60,
          height = 10,
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
        },
      },
    },
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
