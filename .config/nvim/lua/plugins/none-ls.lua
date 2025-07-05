return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				-- Formatting
				null_ls.builtins.formatting.shfmt, -- Bash
				null_ls.builtins.formatting.clang_format, -- C/C++
				null_ls.builtins.formatting.google_java_format, -- Java
				null_ls.builtins.formatting.prettier, -- JavaScript
				null_ls.builtins.formatting.stylua, -- Lua
				null_ls.builtins.formatting.ruff, -- Python

				-- Diagnostics (Linters)
				null_ls.builtins.diagnostics.shellcheck, -- Bash
				null_ls.builtins.diagnostics.cppcheck, -- C/C++
				null_ls.builtins.diagnostics.checkstyle, -- Java
			},
			diagnostics_format = "#{m} (#{s})",

			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					-- Create the augroup first and store its ID
					local group = vim.api.nvim_create_augroup("LspFormatting", { clear = false })

					-- Clear autocommands using the group ID
					vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

					-- Set up the formatting autocommand using the same group ID
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = group,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ timeout_ms = 2000 })
						end,
					})
				end
			end,
		})

		-- Keymaps
		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format buffer" })
		vim.keymap.set("v", "<leader>gf", vim.lsp.buf.format, { desc = "Format selection" })
	end,
}
