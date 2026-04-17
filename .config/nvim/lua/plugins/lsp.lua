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

		-- Servers managed via vim.lsp.config() + vim.lsp.enable() (nvim 0.12 native API).
		-- nvim-lspconfig v2 auto-registers cmd/filetypes/root_markers from its lsp/*.lua
		-- files via the runtimepath. We only need to provide overrides here.
		local lsp_servers = {
			bashls = {
				settings = {
					bash = {
						shellcheckPath = "",
					},
				},
			},
			marksman = {},
			clangd = {},
			gopls = {},
			ty = {},
			cssls = {},
			html = {},
			jsonls = {},
			jdtls = {},
			texlab = {},
			ts_ls = {},
			vimls = {},
			yamlls = {},
			lua_ls = {
				single_file_support = true,
			},
			basedpyright = {},
		}

		-- Mason LSP servers to ensure installed (mason package names).
		-- These must be installed for the corresponding LSP to start.
		local mason_lsp_servers = {
			"bash-language-server",
			"marksman",
			"clangd",
			"gopls",
			"ty",
			"css-lsp",
			"html-lsp",
			"json-lsp",
			"jdtls",
			"texlab",
			"typescript-language-server",
			"vim-language-server",
			"yaml-language-server",
			"lua-language-server",
			"basedpyright",
		}

		-- Non-LSP mason tools (formatters, linters, etc.)
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

		local all_mason_packages = vim.list_extend(vim.list_extend({}, mason_lsp_servers), mason_tools)
		require("mason-tool-installer").setup({ ensure_installed = all_mason_packages })

		-- Initialize mason-lspconfig so it can auto-enable newly installed servers.
		-- automatic_enable is set to false because we manage vim.lsp.enable() ourselves below.
		require("mason-lspconfig").setup({
			automatic_enable = false,
		})

		local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
		lsp_capabilities = require("blink.cmp").get_lsp_capabilities(lsp_capabilities)

		-- Apply capability overrides (and any per-server config overrides) on top of
		-- nvim-lspconfig v2 defaults already registered in the runtimepath.
		for server_name, server_opts in pairs(lsp_servers) do
			local opts = vim.tbl_deep_extend("force", {
				capabilities = lsp_capabilities,
			}, server_opts)

			vim.lsp.config(server_name, opts)
		end

		vim.lsp.enable(vim.tbl_keys(lsp_servers))

		vim.api.nvim_create_user_command("LspLog", function()
			vim.cmd("edit " .. vim.fn.stdpath("state") .. "/lsp.log")
		end, { desc = "Open LSP log file" })

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if not client then
					return
				end

				attach.apply_lsp(event.buf)

				if
					client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
					and not vim.b[event.buf]._lsp_highlight_attached
				then
					vim.b[event.buf]._lsp_highlight_attached = true
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
			end,
		})
	end,
}
