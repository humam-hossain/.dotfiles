return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = false,
			integrations = {
				cmp = true, -- blink.cmp reuses nvim-cmp highlight groups
				gitsigns = true,
				neotree = true, -- replaces stale nvimtree flag (neo-tree is installed)
				treesitter = true,
				markdown = true,
				snacks = {
					enabled = true,
					indent_scope_color = "", -- default = overlay2
				},
				-- REMOVED per D-14: nvimtree (no nvim-tree installed), telescope (no telescope installed)
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}