--- TODO: Global keymaps - smart quit, save/format, tmux navigation ---

-- NOTE: Leader key setup
-- Set leader key to spacebar for custom key combinations
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable the spacebar key's default behavior in Normal and Visual modes
-- This prevents conflicts with our leader key mappings
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true, desc = "Disable spacebar" })

-- NOTE: Auto-save configuration
-- Auto-save on focus lost (conservative, guarded).
-- Guards (all must pass before writing):
--   1. buftype == ""     : real file buffer only — rejects nofile, terminal, quickfix,
--                          fugitive, snacks picker previews, and every other special type
--   2. modifiable        : non-modifiable buffers must never be auto-written
--   3. modified          : skip the write syscall when the buffer is already clean
--   4. bufname ~= ""     : unnamed/scratch buffers have no file path to write to
--   5. filereadable(...)  : the backing file must exist on disk (new unsaved files
--                          without a path should use explicit :write, not autosave)
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local bo = vim.bo[bufnr]
    if bo.buftype == "" and bo.modifiable and bo.modified and bufname ~= "" then
      if vim.fn.filereadable(bufname) == 1 then
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
