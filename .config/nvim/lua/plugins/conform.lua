return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			java = { "google-java-format" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			asm = { "asmfmt" },
			tex = { "latexindent" },
		},
		format_on_save = function(bufnr)
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local ft = vim.bo[bufnr].filetype
			local buftype = vim.bo[bufnr].buftype

			if buftype ~= "" and buftype ~= "acwrite" then
				return false
			end

			if not vim.bo[bufnr].modifiable then
				return false
			end

			if bufname == "" then
				return false
			end

			local excluded = {
				gitcommit = true,
				text = true,
				markdown = true,
				gitrebase = true,
				diff = true,
				NeogitCommitMessage = true,
				["neo-tree"] = true,
				["qf"] = true,
			}

			if excluded[ft] then
				return false
			end

			return { timeout_ms = 500, lsp_format = "fallback" }
		end,
		default_format_options = {
			trim_trailing_whitespace = true,
			format_on_save = true,
		},
	},
}