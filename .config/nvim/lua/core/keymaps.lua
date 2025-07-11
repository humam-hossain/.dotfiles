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
-- FILE OPERATIONS
-- ============================================================================

-- Save current file using Ctrl+S
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", { noremap = true, silent = true, desc = "Save file" })

-- Save file without running auto-formatting commands
vim.keymap.set(
	"n",
	"<leader>sn",
	"<cmd>noautocmd w <CR>",
	{ noremap = true, silent = true, desc = "Save without formatting" }
)

-- Quit current file/buffer using Ctrl+Q
vim.keymap.set("n", "<C-q>", "<cmd> q <CR>", { noremap = true, silent = true, desc = "Quit file" })

-- ============================================================================
-- Mode Shortcut
-- ============================================================================
vim.keymap.set({ "i", "v" }, "jk", "<C-\\><C-n>", { desc = "Switch to normal mode" })

-- ============================================================================
-- EDITING ENHANCEMENTS
-- ============================================================================

-- Delete single character without copying it to the register (clipboard)
-- Useful to avoid polluting your clipboard with single characters
vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true, desc = "Delete char without yanking" })

-- Vertical scroll half page down and center cursor on screen
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true, desc = "Scroll down and center" })

-- Vertical scroll half page up and center cursor on screen
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true, desc = "Scroll up and center" })

-- Find next search result and center it on screen with cursor in middle
vim.keymap.set("n", "n", "nzzzv", { noremap = true, silent = true, desc = "Next search result" })

-- Find previous search result and center it on screen with cursor in middle
vim.keymap.set("n", "N", "Nzzzv", { noremap = true, silent = true, desc = "Previous search result" })

-- ============================================================================
-- Diagnostics, Formatting, Autocompletion
-- ============================================================================
vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float()
end, { desc = "Open Diagnostics in Float" })

vim.keymap.set("n", "<leader>cf", function()
	require("conform").format()
end, { desc = "[C]ode [F]ormat current file" })

-- ============================================================================
-- git
-- ============================================================================
vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "[G]itsigns [P]review" })
vim.keymap.set(
	"n",
	"<leader>gt",
	":Gitsigns toggle_current_line_blame<CR>",
	{ desc = "[G]itsigns [T]oggle Current Line blame" }
)

-- ============================================================================
-- WINDOW RESIZING
-- ============================================================================

-- Decrease window height by 2 lines using Up arrow
vim.keymap.set("n", "<Up>", ":resize -2<CR>", { noremap = true, silent = true, desc = "Decrease window height" })

-- Increase window height by 2 lines using Down arrow
vim.keymap.set("n", "<Down>", ":resize +2<CR>", { noremap = true, silent = true, desc = "Increase window height" })

-- Decrease window width by 2 columns using Left arrow
vim.keymap.set(
	"n",
	"<Left>",
	":vertical resize -2<CR>",
	{ noremap = true, silent = true, desc = "Decrease window width" }
)

-- Increase window width by 2 columns using Right arrow
vim.keymap.set(
	"n",
	"<Right>",
	":vertical resize +2<CR>",
	{ noremap = true, silent = true, desc = "Increase window width" }
)

-- ============================================================================
-- BUFFER NAVIGATION
-- ============================================================================

-- Switch to next buffer in the buffer list
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })

-- Switch to previous buffer in the buffer list
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true, desc = "Previous buffer" })

-- Force close current buffer (discards unsaved changes)
vim.keymap.set("n", "<leader>x", ":bdelete!<CR>", { noremap = true, silent = true, desc = "Close buffer" })

-- Create a new empty buffer
vim.keymap.set("n", "<leader>b", "<cmd> enew <CR>", { noremap = true, silent = true, desc = "New buffer" })

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================

-- Split current window vertically (creates new window to the right)
vim.keymap.set("n", "<leader>v", "<C-w>v", { noremap = true, silent = true, desc = "Split window vertically" })

-- Split current window horizontally (creates new window below)
vim.keymap.set("n", "<leader>h", "<C-w>s", { noremap = true, silent = true, desc = "Split window horizontally" })

-- Make all split windows equal width and height
vim.keymap.set("n", "<leader>se", "<C-w>=", { noremap = true, silent = true, desc = "Make splits equal" })

-- Close current split window
vim.keymap.set("n", "<leader>xs", ":close<CR>", { noremap = true, silent = true, desc = "Close split" })

-- ============================================================================
-- SPLIT WINDOW NAVIGATION
-- ============================================================================

-- Move to window above current one
vim.keymap.set("n", "<C-k>", ":wincmd k<CR>", { noremap = true, silent = true, desc = "Move to window above" })

-- Move to window below current one
vim.keymap.set("n", "<C-j>", ":wincmd j<CR>", { noremap = true, silent = true, desc = "Move to window below" })

-- Move to window to the left of current one
vim.keymap.set("n", "<C-h>", ":wincmd h<CR>", { noremap = true, silent = true, desc = "Move to window left" })

-- Move to window to the right of current one
vim.keymap.set("n", "<C-l>", ":wincmd l<CR>", { noremap = true, silent = true, desc = "Move to window right" })

-- ============================================================================
-- DISPLAY OPTIONS
-- ============================================================================

-- Toggle line wrapping on/off for long lines
vim.keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", { noremap = true, silent = true, desc = "Toggle line wrap" })

-- ============================================================================
-- VISUAL MODE ENHANCEMENTS
-- ============================================================================

-- Stay in indent mode after indenting left - allows for multiple indentations
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true, desc = "Indent left" })

-- Stay in indent mode after indenting right - allows for multiple indentations
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true, desc = "Indent right" })

-- Paste over selected text without losing the original yanked content
-- This prevents the selected text from replacing your clipboard content
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true, desc = "Paste without yanking" })
