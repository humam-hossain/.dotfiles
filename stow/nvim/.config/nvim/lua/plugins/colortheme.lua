--- Colorscheme - black-metal (darkthrone: pure #000000 bg, monochrome) ---
return {
	"metalelf0/black-metal-theme-neovim",
	lazy = false,
	priority = 1000,
	config = function()
		require("black-metal").setup({
			theme = "darkthrone",
			variant = "dark",
			alt_bg = false,
			transparent = false,
			-- stock darkthrone is all grey: keyword/func/constant barely differ
			colors = {
				keyword = "#a06060", -- dusty red: if/for/return/def
				func = "#6f9a9a", -- muted teal: function names and calls
				constant = "#b09a68", -- muted sand: constants, True/None
				number = "#b09a68",
				string = "#8a9a78", -- muted olive
				type = "#8c8cac", -- muted slate: types and classes
				property = "#c1c1c1",
				comment = "#505050",
			},
			code_style = { keywords = "bold", comments = "italic" },
		})
		require("black-metal").load()
	end,
}
