-- ============================================================================
-- NEOVIM KEYMAPS CONFIGURATION
-- ============================================================================

-- Set leader key to spacebar for custom key combinations
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable the spacebar key's default behavior in Normal and Visual modes
-- This prevents conflicts with our leader key mappings
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true, desc = "Disable spacebar" })

-- ============================================================================
-- AUTO-SAVE (non-mapping policy that belongs in core)
-- ============================================================================

-- Auto-save on focus lost (conservative, guarded)
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo.buftype == "" and vim.bo.modifiable and vim.bo.modified and bufname ~= "" then
      local readable = vim.fn.filereadable(bufname) == 1 or vim.fn.bufexists(bufnr) == 1
      if readable then
        vim.cmd("silent! write")
      end
    end
  end,
  desc = "Auto save on focus lost for normal file buffers",
})

-- ============================================================================
-- REGISTRY BOOTSTRAP - Apply global mappings from central registry
-- ============================================================================

-- Apply global mappings from the central registry
require("core.keymaps.apply").apply_global()
