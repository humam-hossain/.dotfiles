return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
	},
	config = function()
		-- 1. Modern Highlight Adjustments
		-- Keep the main line transparent
		vim.api.nvim_set_hl(0, "Folded", { bg = "NONE" })
		
		-- Create a specific highlight for your suffix box
		-- fg="#11111b" (dark text) makes the light blue background readable
		vim.api.nvim_set_hl(0, "UfoSuffixHighlight", { bg = "#89b4fa", fg = "#11111b", bold = true })

		-- set options
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
		vim.opt.fillchars = {
			foldopen = "",
			foldclose = "",
			fold = " ",
			foldsep = " ",
			diff = "╱",
			eob = " ",
			horiz = "━",
			horizup = "┻",
			horizdown = "┳",
			vert = "┃",
			vertleft = "┫",
			vertright = "┣",
			verthoriz = "╋",
		}

		-- Set keymaps
		vim.keymap.set("n", "zR", require("ufo").openAllFolds)
		vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
		vim.keymap.set("n", "zK", function()
			local winid = require("ufo").peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek Fold" })

		-- Custom handler to show number of lines with ...
		local handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText = {}
			-- Added a space at the start/end of suffix for "padding" inside the blue box
			local suffix = (" ...  %d "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			local curWidth = 0
			for _, chunk in ipairs(virtText) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if targetWidth > curWidth + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, targetWidth - curWidth)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if curWidth + chunkWidth < targetWidth then
						suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
					end
					break
				end
				curWidth = curWidth + chunkWidth
			end
			-- APPLY THE CUSTOM HIGHLIGHT HERE
			table.insert(newVirtText, { suffix, "UfoSuffixHighlight" })
			return newVirtText
		end

		require("ufo").setup({
			fold_virt_text_handler = handler,
			provider_selector = function(bufnr, filetype, buftype)
				return { "lsp", "indent" }
			end,
		})
	end,
}
