return {
	{
		"vimpostor/vim-tpipeline",
		event = "VimEnter",
		config = function()
			vim.g.tpipeline_autoembed = 1
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		event = "VeryLazy",
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					section_seperator = "",
					component_seperators = "",
					icons_enabled = true,
					globalstatus = false,
				},
				dependencies = { "nvim-tree/nvim-web-devicons" },
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { {
						"filename",
						path = 1,
					} },
					lualine_x = (function()
						-- Graceful degradation if noice fails to load (see Phase 3 CONCERNS.md, D-08).
						local ok_noice, noice = pcall(require, "noice")
						local x = {}
						if ok_noice and noice and noice.api and noice.api.status then
							table.insert(x, {
								noice.api.status.mode.get,
								cond = noice.api.status.mode.has,
								color = { fg = "#51f7d3" },
							})
							table.insert(x, {
								noice.api.status.command.get,
								cond = noice.api.status.command.has,
								color = { fg = "#51f7d3" },
							})
						end
						table.insert(x, "filetype")
						return x
					end)(),
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
			vim.o.laststatus = 0
		end,
	},
}
