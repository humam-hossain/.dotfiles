-- project.nvim: use pattern-only detection to avoid vim.lsp.buf_get_clients()
-- deprecation warnings on Neovim 0.12+.
return {
	"ahmedkhalf/project.nvim",
	init = function()
		require("project_nvim").setup({
			-- project.nvim's LSP probe still calls deprecated vim.lsp.buf_get_clients().
			-- Pattern detection preserves project-root behavior without the 0.12 warning.
			detection_methods = { "pattern" },
		})
	end,
}
