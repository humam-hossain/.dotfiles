--- TODO: UI enhancements - snacks.nvim dashboard/notifier/picker ---
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	-- KEY-01: wire all lazy keymaps from central registry via lazy.nvim
	keys = function()
		return require("core.keymaps.lazy").get_all_keys()
	end,
	---@type snacks.Config
	opts = {
		notifier = {
			enabled = true,
			timeout = 3000,
			top_down = false, -- D-04: bottom-right toast accumulation
		},
		dashboard = {
			enabled = true, -- D-05: default/minimal dashboard, no ASCII art port
		},
		picker = {
			enabled = true, -- D-06: replaces fzf-lua; wired via registry
			hidden = true,
			ignored = true,
			previewers = {
				diff = { style = "syntax" }, -- avoid treesitter injection nil node bug (nvim-treesitter compat)
			},
		},
		indent = {
			enabled = true, -- D-08: replaces indent-blankline
		},
		scroll = {
			enabled = true, -- D-10: smooth scroll for <C-d>/<C-u>
		},
		words = {
			enabled = true, -- D-09: LSP word highlights
		},
		lazygit = {
			enabled = true, -- D-07: wired in registry as <leader>gg
		},
		explorer = {
			enabled = true,
			replace_netrw = true,
			trash = true,
		},
		quickfile = {
			enabled = true, -- fast file render before full lazy load (UX-02)
		},
		image = {
			enabled = false, -- D-11: not needed
		},
		terminal = {
			enabled = false, -- D-12: kitty+tmux already provides terminal workflow
		},
		zen = {
			enabled = false, -- D-12: no established use case
		},
	},
	config = function(_, opts)
		require("snacks").setup(opts)
		vim.ui.select = Snacks.picker.select
	end,
}
