return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "mason-org/mason.nvim", opts = {} },
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		"saghen/blink.cmp",
	},
	config = function()
		local attach = require("core.keymaps.attach")

		vim.diagnostic.config({
			severity_sort = true,
			float = { border = "rounded", source = "if_many" },
			underline = true,
			update_in_insert = true,
			signs = vim.g.have_nerd_font and {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
			} or {},
			virtual_text = {
				source = "if_many",
				spacing = 2,
				format = function(diagnostic)
					local diagnostic_message = {
						[vim.diagnostic.severity.ERROR] = diagnostic.message,
						[vim.diagnostic.severity.WARN] = diagnostic.message,
						[vim.diagnostic.severity.INFO] = diagnostic.message,
						[vim.diagnostic.severity.HINT] = diagnostic.message,
					}
					return diagnostic_message[diagnostic.severity]
				end,
			},
		})

		local lsp_servers = {
			bashls = {},
			marksman = {},
			clangd = {},
			gopls = {},
			ty = {},
			eslint_d = {},
			cssls = {},
			html = {},
			jsonls = {},
			jdtls = {},
			texlab = {},
			ts_ls = {},
			vimls = {},
			yamlls = {},
			lua_ls = {},
		}

		local mason_tools = {
			"stylua",
			"asmfmt",
			"clang-format",
			"prettierd",
			"prettier",
			"isort",
			"black",
			"google-java-format",
			"latexindent",
			"shfmt",
		}

		require("mason-tool-installer").setup({ ensure_installed = mason_tools })

		local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
		lsp_capabilities = require("blink.cmp").get_lsp_capabilities(lsp_capabilities)

		for server_name, server_opts in pairs(lsp_servers) do
			local opts = vim.tbl_deep_extend("force", {
				capabilities = lsp_capabilities,
			}, server_opts)

			vim.lsp.config(server_name, opts)
		end

		vim.lsp.enable(vim.tbl_keys(lsp_servers))

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if not client then
					return
				end

				attach.apply_lsp(event.buf)

				if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
					local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
						end,
					})
				end

				if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
					vim.keymap.set("n", "<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, { buffer = event.buf, desc = "[T]oggle Inlay [H]ints" })
				end
			end,
		})
	end,
}