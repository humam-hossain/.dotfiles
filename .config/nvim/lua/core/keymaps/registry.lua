--- TODO: Declarative keymap registry - id, lhs, mode, desc, domain, scope ---

-- ============================================================================
-- KEYMAP REGISTRY - Central source of truth for all custom mappings
-- ============================================================================
-- This module declares every custom keymap with explicit metadata:
--   id: stable identifier for the mapping
--   lhs: key sequence
--   mode: normal, insert, visual, etc.
--   desc: human-readable description
--   domain: taxonomy prefix (f=search, c=code, g=git, e=explorer, b=buffers, w=windows, t=toggles, s=save)
--   scope: global, lazy, buffer, plugin-local
--   plugin: optional plugin dependency
--   action: the function or command to execute
--   opts: additional vim.keymap.set options

local M = {}

-- ============================================================================
-- GLOBAL MAPPINGS (applied immediately at startup)
-- ============================================================================
M.global = {
  -- Mode switch
  {
    id = "mode.switch_escape",
    lhs = "jk",
    mode = { "i", "v" },
    desc = "Switch to normal mode",
    domain = "t",
    scope = "global",
    action = "<C-\\><C-n>",
    opts = { noremap = true, silent = true },
  },

  -- Editing enhancements
  {
    id = "edit.delete_char",
    lhs = "x",
    mode = "n",
    desc = "Delete char without yanking",
    domain = "e",
    scope = "global",
    action = '"_x',
    opts = { noremap = true, silent = true },
  },
  {
    id = "edit.scroll_down",
    lhs = "<C-d>",
    mode = "n",
    desc = "Scroll down and center",
    domain = "w",
    scope = "global",
    action = "<C-d>zz",
    opts = { noremap = true, silent = true },
  },
  {
    id = "edit.scroll_up",
    lhs = "<C-u>",
    mode = "n",
    desc = "Scroll up and center",
    domain = "w",
    scope = "global",
    action = "<C-u>zz",
    opts = { noremap = true, silent = true },
  },
  {
    id = "edit.search_next",
    lhs = "n",
    mode = "n",
    desc = "Next search result",
    domain = "f",
    scope = "global",
    action = "nzzzv",
    opts = { noremap = true, silent = true },
  },
  {
    id = "edit.search_prev",
    lhs = "N",
    mode = "n",
    desc = "Previous search result",
    domain = "f",
    scope = "global",
    action = "Nzzzv",
    opts = { noremap = true, silent = true },
  },

  -- Comment toggle (preserved direct key)
  {
    id = "edit.toggle_comment_normal",
    lhs = "<C-_>",
    mode = "n",
    desc = "Toggle comment",
    domain = "e",
    scope = "global",
    action = "gcc",
    opts = { remap = true },
  },
  {
    id = "edit.toggle_comment_insert",
    lhs = "<C-_>",
    mode = "i",
    desc = "Toggle comment",
    domain = "e",
    scope = "global",
    action = "<ESC>gcca",
    opts = { remap = true },
  },
  {
    id = "edit.toggle_comment_visual",
    lhs = "<C-_>",
    mode = "v",
    desc = "Toggle comment",
    domain = "e",
    scope = "global",
    action = "gc",
    opts = { remap = true },
  },

  -- Window navigation: <C-h/j/k/l> are owned by vim-tmux-navigator (plugins/misc.lua).
  -- Registry mappings removed per D-01/D-03 so the plugin's split+tmux-pane crossing works
  -- without being shadowed by startup-time registry globals.
  {
    id = "window.cycle",
    lhs = "<leader>ww",
    mode = "n",
    desc = "Cycle to next window",
    domain = "w",
    scope = "global",
    action = "<C-w>w",
    opts = { noremap = true, silent = true },
  },

  -- Window resize (arrow keys)
  {
    id = "window.resize_up",
    lhs = "<Up>",
    mode = "n",
    desc = "Decrease window height",
    domain = "w",
    scope = "global",
    action = ":resize +2<CR>",
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.resize_down",
    lhs = "<Down>",
    mode = "n",
    desc = "Increase window height",
    domain = "w",
    scope = "global",
    action = ":resize -2<CR>",
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.resize_left",
    lhs = "<Left>",
    mode = "n",
    desc = "Decrease window width",
    domain = "w",
    scope = "global",
    action = ":vertical resize +2<CR>",
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.resize_right",
    lhs = "<Right>",
    mode = "n",
    desc = "Increase window width",
    domain = "w",
    scope = "global",
    action = ":vertical resize -2<CR>",
    opts = { noremap = true, silent = true },
  },

  -- Buffer navigation (preserved direct keys)
  {
    id = "buffer.next",
    lhs = "<Tab>",
    mode = "n",
    desc = "Next buffer",
    domain = "b",
    scope = "global",
    action = ":bnext<CR>",
    opts = { noremap = true, silent = true },
  },
  {
    id = "buffer.prev",
    lhs = "<S-Tab>",
    mode = "n",
    desc = "Previous buffer",
    domain = "b",
    scope = "global",
    action = ":bprevious<CR>",
    opts = { noremap = true, silent = true },
  },

  -- Diagnostics
  {
    id = "diagnostics.float",
    lhs = "gl",
    mode = "n",
    desc = "Open Diagnostics in Float",
    domain = "c",
    scope = "global",
    action = function()
      vim.diagnostic.open_float({ focusable = true })
    end,
    opts = { noremap = true, silent = true },
  },

  -- Open file externally (preserved direct key)
  {
    id = "file.open_external",
    lhs = "<C-S-o>",
    mode = "n",
    desc = "Open file with default application",
    domain = "f",
    scope = "global",
    action = function()
      require("core.open").open_current_buffer()
    end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "file.jump_forward",
    lhs = "<C-i>",
    mode = "n",
    desc = "Jump forward",
    domain = "w",
    scope = "global",
    action = "<C-i>",
    opts = { noremap = true },
  },

  -- Visual mode enhancements
  {
    id = "visual.indent_left",
    lhs = "<",
    mode = "v",
    desc = "Indent left",
    domain = "e",
    scope = "global",
    action = "<gv",
    opts = { noremap = true, silent = true },
  },
  {
    id = "visual.indent_right",
    lhs = ">",
    mode = "v",
    desc = "Indent right",
    domain = "e",
    scope = "global",
    action = ">gv",
    opts = { noremap = true, silent = true },
  },
  {
    id = "visual.paste_preserve",
    lhs = "p",
    mode = "v",
    desc = "Paste without yanking",
    domain = "e",
    scope = "global",
    action = '"_dP',
    opts = { noremap = true, silent = true },
  },

  -- Buffer management (eager/shared controls, not plugin-trigger lazy keys)
  {
    id = "buffer.new",
    lhs = "<leader>b",
    mode = "n",
    desc = "New buffer",
    domain = "b",
    scope = "global",
    action = function() vim.cmd("enew") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "buffer.close",
    lhs = "<leader>x",
    mode = "n",
    desc = "Close buffer",
    domain = "b",
    scope = "global",
    action = ":bdelete!<CR>",
    opts = { noremap = true, silent = true },
  },

  -- Window management (eager/shared controls)
  {
    id = "window.split_vert",
    lhs = "<leader>v",
    mode = "n",
    desc = "Split window vertically",
    domain = "w",
    scope = "global",
    action = function() vim.cmd("vsplit") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.split_horiz",
    lhs = "<leader>h",
    mode = "n",
    desc = "Split window horizontally",
    domain = "w",
    scope = "global",
    action = function() vim.cmd("split") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.equalize",
    lhs = "<leader>se",
    mode = "n",
    desc = "Make splits equal",
    domain = "w",
    scope = "global",
    action = function() vim.cmd("wincmd =") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.close_split",
    lhs = "<leader>xs",
    mode = "n",
    desc = "Close split",
    domain = "w",
    scope = "global",
    action = function() vim.cmd("close") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "window.picker",
    lhs = "<leader>wm",
    mode = "n",
    desc = "Pick a window to switch to",
    domain = "w",
    scope = "global",
    action = function()
      local wins = vim.api.nvim_list_wins()
      local choices = {}
      for _, w in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(w)
        local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf)) or "[No Name]"
        table.insert(choices, string.format("Window %d: %s", w, name))
      end
      vim.ui.select(choices, { prompt = "Pick window:" }, function(choice)
        if choice then
          local win_id = tonumber(choice:match("Window (%d+)"))
          if win_id then
            vim.api.nvim_set_current_win(win_id)
          end
        end
      end)
    end,
    opts = { noremap = true, silent = true },
  },

  -- Toggle domain (eager/shared controls)
  {
    id = "toggle.line_wrap",
    lhs = "<leader>lw",
    mode = "n",
    desc = "Toggle line wrap",
    domain = "t",
    scope = "global",
    action = function() vim.wo.wrap = not vim.wo.wrap end,
    opts = { noremap = true, silent = true },
  },

  -- Save domain (eager/shared controls)
  {
    id = "save.format_and_write",
    lhs = "<C-s>",
    mode = "n",
    desc = "Save and format file",
    domain = "s",
    scope = "global",
    action = function()
      require("conform").format({ async = false, lsp_fallback = true })
      vim.cmd("w")
    end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "save.no_format",
    lhs = "<leader>sn",
    mode = "n",
    desc = "Save without formatting",
    domain = "s",
    scope = "global",
    action = function() vim.cmd("noautocmd w") end,
    opts = { noremap = true, silent = true },
  },
  {
    id = "save.close_buffer",
    lhs = "<C-q>",
    mode = "n",
    desc = "Close current buffer",
    domain = "b",
    scope = "global",
    action = function()
      vim.cmd("confirm bdelete")
    end,
    opts = { noremap = true, silent = true },
  },
}

-- ============================================================================
-- LAZY MAPPINGS (loaded on key trigger via lazy.nvim)
-- ============================================================================
M.lazy = {
-- Search domain (f)
  {
    id = "search.files",
    lhs = "<leader>ff",
    mode = "n",
    desc = "Find Files in project directory",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.files() end,
  },
  {
    id = "search.grep",
    lhs = "<leader>fg",
    mode = "n",
    desc = "Find by grepping in project directory",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.grep({ hidden = true, ignored = false }) end,
  },
  {
    id = "search.config",
    lhs = "<leader>fc",
    mode = "n",
    desc = "Find in neovim configuration",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end,
  },
  {
    id = "search.help",
    lhs = "<leader>fh",
    mode = "n",
    desc = "Find Help",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.help() end,
  },
  {
    id = "search.keymaps",
    lhs = "<leader>fk",
    mode = "n",
    desc = "Find Keymaps",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.keymaps() end,
  },
  {
    id = "search.builtin",
    lhs = "<leader>fb",
    mode = "n",
    desc = "Find Builtin FZF",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker() end,
  },
  {
    id = "search.word",
    lhs = "<leader>fw",
    mode = "n",
    desc = "Find current Word",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.grep_word() end,
  },
  {
    id = "search.WORD",
    lhs = "<leader>fW",
    mode = "n",
    desc = "Find current WORD",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.grep_word() end,
  },
  {
    id = "search.diagnostics",
    lhs = "<leader>fd",
    mode = "n",
    desc = "Find Diagnostics",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.diagnostics() end,
  },
  {
    id = "search.resume",
    lhs = "<leader>fr",
    mode = "n",
    desc = "Find Resume",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.resume() end,
  },
  {
    id = "search.oldfiles",
    lhs = "<leader>fo",
    mode = "n",
    desc = "Find Old Files",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.recent() end,
  },
  {
    id = "buffers.list",
    lhs = "<leader>,",
    mode = "n",
    desc = "Find existing buffers",
    domain = "b",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.buffers() end,
  },
  {
    id = "search.grep_curbuf",
    lhs = "<leader>/",
    mode = "n",
    desc = "Live grep the current buffer",
    domain = "f",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.lines() end,
  },

  -- Git domain (g)
  {
    id = "git.lazygit",
    lhs = "<leader>gg",
    mode = "n",
    desc = "Open LazyGit",
    domain = "g",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.lazygit() end,
  },
  {
    id = "git.preview_hunk",
    lhs = "<leader>gp",
    mode = "n",
    desc = "Gitsigns Preview",
    domain = "g",
    scope = "lazy",
    plugin = "lewis6991/gitsigns.nvim",
    action = function() require("gitsigns").preview_hunk() end,
  },
  {
    id = "git.toggle_blame",
    lhs = "<leader>gt",
    mode = "n",
    desc = "Gitsigns Toggle Current Line blame",
    domain = "g",
    scope = "lazy",
    plugin = "lewis6991/gitsigns.nvim",
    action = function() require("gitsigns").toggle_current_line_blame() end,
  },
  {
    id = "git.status",
    lhs = "<leader>gs",
    mode = "n",
    desc = "Open git status window",
    domain = "g",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.git_status() end,
  },
  {
    id = "git.log",
    lhs = "<leader>gl",
    mode = "n",
    desc = "Open git log",
    domain = "g",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.git_log() end,
  },
  {
    id = "git.branches",
    lhs = "<leader>gb",
    mode = "n",
    desc = "Open git branches",
    domain = "g",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.git_branches() end,
  },
  {
    id = "git.diff",
    lhs = "<leader>gd",
    mode = "n",
    desc = "Open diff hunks",
    domain = "g",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.picker.git_diff() end,
  },

  -- Explorer domain (e)
  {
    id = "explorer.toggle",
    lhs = "<leader>e",
    mode = "n",
    desc = "Toggle file explorer",
    domain = "e",
    scope = "lazy",
    plugin = "folke/snacks.nvim",
    action = function() Snacks.explorer() end,
  },

  -- UFO fold mappings
  {
    id = "fold.open_all",
    lhs = "zR",
    mode = "n",
    desc = "Open all folds",
    domain = "t",
    scope = "lazy",
    plugin = "kevinhwang91/nvim-ufo",
    action = function()
      require("ufo").openAllFolds()
    end,
  },
  {
    id = "fold.close_all",
    lhs = "zM",
    mode = "n",
    desc = "Close all folds",
    domain = "t",
    scope = "lazy",
    plugin = "kevinhwang91/nvim-ufo",
    action = function()
      require("ufo").closeAllFolds()
    end,
  },
  {
    id = "fold.peek",
    lhs = "zK",
    mode = "n",
    desc = "Peek Fold",
    domain = "t",
    scope = "lazy",
    plugin = "kevinhwang91/nvim-ufo",
    action = function()
      local winid = require("ufo").peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end,
  },
}

-- ============================================================================
-- BUFFER-LOCAL MAPPINGS (applied on LSP attach)
-- ============================================================================
M.buffer = {
  -- LSP actions (attached to buffers with LSP)
  {
    id = "lsp.rename",
    lhs = "<leader>cn",
    mode = "n",
    desc = "Rename symbol",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = vim.lsp.buf.rename,
  },
  {
    id = "lsp.code_action",
    lhs = "<leader>ca",
    mode = { "n", "x" },
    desc = "Goto Code Action",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = vim.lsp.buf.code_action,
  },
  {
    id = "lsp.references",
    lhs = "<leader>cr",
    mode = "n",
    desc = "Goto Code References",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_references() end,
  },
  {
    id = "lsp.implementations",
    lhs = "<leader>ci",
    mode = "n",
    desc = "Goto Code Implementation",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_implementations() end,
  },
  {
    id = "lsp.definition",
    lhs = "<leader>cd",
    mode = "n",
    desc = "Goto Code Definition",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_definitions() end,
  },
  {
    id = "lsp.typedefs",
    lhs = "grt",
    mode = "n",
    desc = "Goto Type Definition",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_type_definitions() end,
  },
  {
    id = "lsp.declaration",
    lhs = "<leader>cD",
    mode = "n",
    desc = "Goto Code Declaration",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = vim.lsp.buf.declaration,
  },
  {
    id = "lsp.doc_symbols",
    lhs = "gO",
    mode = "n",
    desc = "Open Document Symbols",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_symbols() end,
  },
  {
    id = "lsp.workspace_symbols",
    lhs = "gW",
    mode = "n",
    desc = "Open Workspace Symbols",
    domain = "c",
    scope = "buffer",
    attach = "LspAttach",
    action = function() Snacks.picker.lsp_workspace_symbols() end,
  },
  {
    id = "lsp.toggle_inlay",
    lhs = "<leader>th",
    mode = "n",
    desc = "Toggle Inlay Hints",
    domain = "t",
    scope = "buffer",
    attach = "LspAttach",
    action = function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end,
  },
}

-- ============================================================================
-- PLUGIN-LOCAL MAPPINGS (scoped to specific plugin contexts)
-- ============================================================================
M.plugin_local = {
  -- CSV view navigation (scoped to CSV buffers)
  {
    id = "csvview.next_field",
    lhs = "<Tab>",
    mode = { "n", "v" },
    desc = "Jump to next field",
    domain = "b",
    scope = "plugin-local",
    attach = "csvview",
    action = "jump_next_field_end",
  },
  {
    id = "csvview.prev_field",
    lhs = "<S-Tab>",
    mode = { "n", "v" },
    desc = "Jump to previous field",
    domain = "b",
    scope = "plugin-local",
    attach = "csvview",
    action = "jump_prev_field_end",
  },
  {
    id = "csvview.next_row",
    lhs = "<Enter>",
    mode = { "n", "v" },
    desc = "Jump to next row",
    domain = "b",
    scope = "plugin-local",
    attach = "csvview",
    action = "jump_next_row",
  },
  {
    id = "csvview.prev_row",
    lhs = "<S-Enter>",
    mode = { "n", "v" },
    desc = "Jump to previous row",
    domain = "b",
    scope = "plugin-local",
    attach = "csvview",
    action = "jump_prev_row",
  },
}

-- ============================================================================
-- DOMAIN GROUPS (for which-key registration)
-- ============================================================================
M.groups = {
  { prefix = "f", group = "search", label = "Search" },
  { prefix = "c", group = "code", label = "Code/LSP" },
  { prefix = "g", group = "git", label = "Git" },
  { prefix = "e", group = "explorer", label = "Explorer" },
  { prefix = "b", group = "buffers", label = "Buffers" },
  { prefix = "w", group = "windows", label = "Windows" },
  { prefix = "t", group = "toggles", label = "Toggles" },
  { prefix = "s", group = "save", label = "Save/Session" },
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get all mappings of a specific scope
function M.get_by_scope(scope)
  if scope == "global" then
    return M.global
  elseif scope == "lazy" then
    return M.lazy
  elseif scope == "buffer" then
    return M.buffer
  elseif scope == "plugin-local" then
    return M.plugin_local
  end
  return {}
end

-- Get mappings by domain
function M.get_by_domain(domain)
  local result = {}
  for _, scope_tbl in ipairs({ M.global, M.lazy, M.buffer, M.plugin_local }) do
    for _, map in ipairs(scope_tbl) do
      if map.domain == domain then
        table.insert(result, map)
      end
    end
  end
  return result
end

-- Get mapping by ID
function M.get_by_id(id)
  for _, scope_tbl in ipairs({ M.global, M.lazy, M.buffer, M.plugin_local }) do
    for _, map in ipairs(scope_tbl) do
      if map.id == id then
        return map
      end
    end
  end
  return nil
end

return M