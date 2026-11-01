--- TODO: Format on save - conform + per-language formatter arguments ---
-- Indentation contract: every formatter below is pinned to 4-space indentation.
-- Several of them default to 2 (google-java-format, clang-format, prettier,
-- latexindent), so leaving them unconfigured silently rewrites files to 2 on
-- every save. The flags here override any project-local formatter config.

-- clang-format ships LLVM style (2-space indent) and reads .clang-format files
-- from the tree; an explicit --style on the command line wins over both.
local clang_format_args = {
	"-assume-filename",
	"$FILENAME",
	"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, ContinuationIndentWidth: 8, UseTab: Never, AccessModifierOffset: -4}",
}

return {
	"stevearc/conform.nvim",
	init = function()
		-- prettierd cannot take formatter options on the command line, so point it
		-- at a default config (4-space indent) used when the project has none.
		local prettierrc = vim.fs.joinpath(vim.fn.stdpath("config"), ".prettierrc.json")
		if vim.uv.fs_stat(prettierrc) then
			vim.env.PRETTIERD_DEFAULT_CONFIG = prettierrc
		end
	end,
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			-- yamlls formats through bundled prettier (always 2 spaces), so format
			-- YAML with our prettier config first and skip the LSP fallback.
			yaml = { "prettierd", "prettier", stop_after_first = true },
			-- google-java-format hardcodes 2-space indentation in its default
			-- (Google) style; --aosp is the same formatter with 4-space indentation.
			java = { "google-java-format" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			asm = { "asmfmt" },
			-- latexindent defaults to a 2-space defaultIndent.
			tex = { "latexindent" },
		},
		-- Per-formatter argument overrides. These must live here (not as nested
		-- { "name", args = ... } entries in formatters_by_ft, which conform rejects).
		formatters = {
			["google-java-format"] = { args = { "--aosp", "-" } },
			["clang-format"] = { args = clang_format_args },
			prettier = { args = { "--tab-width", "4", "--stdin-filepath", "$FILENAME" } },
			latexindent = { args = { "-y=defaultIndent: '    '", "-" } },
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
