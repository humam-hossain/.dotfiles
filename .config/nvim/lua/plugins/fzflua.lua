return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {},
	keys = require("core.keymaps.lazy").search_keys(),
}