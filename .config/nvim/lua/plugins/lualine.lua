return {
	{
		"vimpostor/vim-tpipeline",
		event = "VimEnter",
		config = function()
			vim.g.tpipeline_autoembed = 1
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					section_seperator = "",
					component_seperators = "",
					icons_enabled = true,
					globalstatus = false,
				},
				dependencies = { "nvim-tree/nvim-web-devicons" },
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { {
						"filename",
						path = 1,
					} },
					lualine_x = {
						-- 1. MACRO RECORDING (handled by Noice)
						{
							require("noice").api.status.mode.get,
							cond = require("noice").api.status.mode.has,
							color = { fg = "#51f7d3" },
						},
						-- 2. COMMAND / KEYSTROKES (shows pending keys like "d2...")
						{
							require("noice").api.status.command.get,
							cond = require("noice").api.status.command.has,
							color = { fg = "#51f7d3" },
						},
						"filetype"
					},
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
			vim.o.laststatus = 0
		end,
	},
}
