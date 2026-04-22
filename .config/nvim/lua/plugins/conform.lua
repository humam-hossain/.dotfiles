--- TODO: Format-on-save dispatcher - conform.nvim ---
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

			-- Guard 1: reject special-buffer types.
			-- "acwrite" (e.g. fugitive commit message) is allowed through because
			-- it is a real file that the user is intentionally editing and saving.
			-- All other non-empty buftype values (nofile, terminal, quickfix, prompt,
			-- etc.) must never enter the formatter code path.
			if buftype ~= "" and buftype ~= "acwrite" then
				return false
			end

			-- Guard 2: non-modifiable buffers must never be formatted on save.
			if not vim.bo[bufnr].modifiable then
				return false
			end

			-- Guard 3: unnamed/scratch buffers have no file path; skip them.
			if bufname == "" then
				return false
			end

			-- Guard 4: filetype exclusion list.
			-- Covers commit messages, plain text, markdown, rebase scripts, diff
			-- output, Neogit commit message, legacy neo-tree, quickfix, and fugitive
			-- status/blame/log buffers (identified by ft "fugitive" / "git").
			local excluded = {
				gitcommit = true,
				text = true,
				markdown = true,
				gitrebase = true,
				diff = true,
				NeogitCommitMessage = true,
				["neo-tree"] = true,
				["qf"] = true,
				-- fugitive status / blame / log windows use ft "fugitive" or "git"
				fugitive = true,
				git = true,
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
