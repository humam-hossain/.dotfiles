--- TODO: Statusline - lualine, tmux guard ---
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
					globalstatus = true, -- D-16: single statusline for all splits
				},
				dependencies = { "nvim-tree/nvim-web-devicons" },
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { {
						"filename",
						path = 1,
					} },
					-- D-18: noice component removed; clean static list
					lualine_x = { "filetype", "encoding" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})

			-- D-17: guard laststatus on tmux presence
			-- Inside tmux, vim-tpipeline forwards lualine render to tmux status;
			-- neovim hides its own statusline via laststatus=0. Outside tmux
			-- (direct terminal, Windows, VS Code), show statusline inside nvim
			-- via laststatus=3 (globalstatus).
			if vim.env.TMUX then
				vim.o.laststatus = 0
			else
				vim.o.laststatus = 3
			end
		end,
	},
}