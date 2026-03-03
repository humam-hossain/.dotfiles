return {
	{
		"bjarneo/hackerman.nvim",
		dependencies = {
			"bjarneo/aether.nvim",
		},
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("hackerman")
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = false,
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					telescope = true,
					treesitter = true,
					markdown = true,
				},
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
