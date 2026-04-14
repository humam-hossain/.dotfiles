# Phase 2: Keymap Inventory

**Generated:** 2026-04-15
**Purpose:** Complete audit of all direct/custom mappings for Phase 2 central control plane

---

## Classification Summary

| Category | Count | Classification |
|----------|-------|----------------|
| Global Direct | 15 | preserve (intentional non-leader keys) |
| Buffer-Local Direct | 0 | N/A (handled via attach) |
| Plugin-Local Direct | ~40 | plugin-local-only (neo-tree, csvview) |
| Lazy (leader-triggered) | 35 | preserve (from registry) |
| **Total** | **~90** | |

---

## Global Direct Keys (Preserved)

These non-leader keys are explicitly preserved per D-06:

| LHS | Mode | Action | Description | Domain |
|-----|------|--------|--------------|--------|
| `jk` | i/v | `<C-\><C-n>` | Switch to normal mode | t |
| `<C-h>` | n | `:wincmd h` | Move to window left | w |
| `<C-j>` | n | `:wincmd j` | Move to window below | w |
| `<C-k>` | n | `:wincmd k` | Move to window above | w |
| `<C-l>` | n | `:wincmd l` | Move to window right | w |
| `<C-_>` | n/i/v | gcc/gcca/gc | Toggle comment | e |
| `<Tab>` | n | `:bnext` | Next buffer | b |
| `<S-Tab>` | n | `:bprevious` | Previous buffer | b |
| `<Up>` | n | `:resize +2` | Decrease window height | w |
| `<Down>` | n | `:resize -2` | Increase window height | w |
| `<Left>` | n | `:vertical resize +2` | Decrease window width | w |
| `<Right>` | n | `:vertical resize -2` | Increase window width | w |
| `<C-i>` | n | `<C-i>` | Jump forward | w |
| `<C-S-o>` | n | `core.open.open_current_buffer` | Open file externally | f |
| `x` | n | `"_x` | Delete without yanking | e |
| `n` | n | `nzzzv` | Next search result | f |
| `N` | n | `Nzzzv` | Previous search result | f |
| `<C-d>` | n | `<C-d>zz` | Scroll down and center | w |
| `<C-u>` | n | `<C-u>zz` | Scroll up and center | w |

---

## Lazy Mappings (Leader-Prefixed)

All leader-prefixed mappings are now declared in the central registry and loaded via lazy.nvim key-trigger.

### Search Domain (`f`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>ff` | `fzf-lua.files()` | Find Files |
| `<leader>fg` | `fzf-lua.live_grep` | Find by grep |
| `<leader>fc` | `fzf-lua.files(cwd=config)` | Find in neovim config |
| `<leader>fh` | `fzf-lua.helptags` | Find Help |
| `<leader>fk` | `fzf-lua.keymaps` | Find Keymaps |
| `<leader>fb` | `fzf-lua.builtin` | Find Builtin FZF |
| `<leader>fw` | `fzf-lua.grep_cword` | Find current Word |
| `<leader>fW` | `fzf-lua.grep_cWORD` | Find current WORD |
| `<leader>fd` | `fzf-lua.diagnostics_document` | Find Diagnostics |
| `<leader>fr` | `fzf-lua.resume` | Find Resume |
| `<leader>fo` | `fzf-lua.oldfiles` | Find Old Files |
| `<leader><leader>` | `fzf-lua.buffers` | Find existing buffers |
| `<leader>/` | `fzf-lua.lgrep_curbuf` | Live grep current buffer |

### Code Domain (`c`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>cf` | `conform.format()` | Code Format |
| `<leader>cn` | `vim.lsp.buf.rename` | Rename (buffer-local) |
| `<leader>ca` | `vim.lsp.buf.code_action` | Code Action (buffer-local) |
| `<leader>cr` | `fzf-lua.lsp_references` | Code References (buffer-local) |
| `<leader>ci` | `fzf-lua.lsp_implementations` | Code Implementation (buffer-local) |
| `<leader>cd` | `fzf-lua.lsp_definitions` | Code Definition (buffer-local) |
| `<leader>cD` | `vim.lsp.buf.declaration` | Code Declaration (buffer-local) |
| `grt` | `fzf-lua.lsp_typedefs` | Goto Type Definition (buffer-local) |
| `gO` | `fzf-lua.lsp_document_symbols` | Open Document Symbols (buffer-local) |
| `gW` | `fzf-lua.lsp_live_workspace_symbols` | Open Workspace Symbols (buffer-local) |
| `<leader>th` | `vim.lsp.inlay_hint.enable()` | Toggle Inlay Hints (buffer-local) |

### Git Domain (`g`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>gp` | `:Gitsigns preview_hunk` | Gitsigns Preview |
| `<leader>gt` | `:Gitsigns toggle_current_line_blame` | Toggle blame |
| `<leader>ngs` | `:Neotree float git_status` | Git status window |

### Explorer Domain (`e`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>e` | `:Neotree toggle` | Toggle file explorer |
| `\` | `:Neotree reveal` | Reveal file in Neo-tree |
| `<leader>nf` | `:Neotree filesystem reveal` | Reveal current file |

### Buffer Domain (`b`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>b` | `:enew` | New buffer |
| `<leader>x` | `:bdelete!` | Close buffer |
| `<leader>nb` | `:Neotree toggle show buffers` | Toggle buffer list |

### Window Domain (`w`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>v` | `<C-w>v` | Split vertically |
| `<leader>h` | `<C-w>s` | Split horizontally |
| `<leader>se` | `<C-w>=` | Make splits equal |
| `<leader>xs` | `:close` | Close split |

### Toggle Domain (`t`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<leader>lw` | `:set wrap!` | Toggle line wrap |
| `zR` | `ufo.openAllFolds` | Open all folds |
| `zM` | `ufo.closeAllFolds` | Close all folds |
| `zK` | `ufo.peekFoldedLines` | Peek fold |

### Save Domain (`s`)

| LHS | Action | Description |
|-----|--------|--------------|
| `<C-s>` | `conform.format() + w` | Save and format |
| `<leader>sn` | `:noautocmd w` | Save without formatting |
| `<C-q>` | `:confirm bdelete` | Close buffer |

---

## Plugin-Local Mappings (Context-Specific)

These mappings only apply in specific plugin contexts and are scoped accordingly.

### Neo-tree Window Mappings

| Key | Action | Context |
|-----|--------|---------|
| `l` | open | neo-tree filesystem |
| `S` | open_split | neo-tree filesystem |
| `s` | open_vsplit | neo-tree filesystem |
| `t` | open_tabnew | neo-tree filesystem |
| `w` | open_with_window_picker | neo-tree filesystem |
| `a` | add | neo-tree filesystem |
| `d` | delete | neo-tree filesystem |
| `r` | rename | neo-tree filesystem |
| `q` | close_window | neo-tree |
| `H` | toggle_hidden | neo-tree filesystem |
| `/` | fuzzy_finder | neo-tree filesystem |
| `P` | toggle_preview | neo-tree |
| `z` | close_all_nodes | neo-tree |
| `Z` | expand_all_nodes | neo-tree |
| `c` | copy | neo-tree |
| `m` | move | neo-tree |
| `y` | copy_to_clipboard | neo-tree |
| `x` | cut_to_clipboard | neo-tree |
| `p` | paste_from_clipboard | neo-tree |
| `R` | refresh | neo-tree |

### CSV View Mappings

| Key | Action | Context |
|-----|--------|---------|
| `<Tab>` | jump_next_field_end | CSV buffers (n/v) |
| `<S-Tab>` | jump_prev_field_end | CSV buffers (n/v) |
| `<Enter>` | jump_next_row | CSV buffers (n/v) |
| `<S-Enter>` | jump_prev_row | CSV buffers (n/v) |

---

## Migration Status

- [x] Central registry created (`core/keymaps/registry.lua`)
- [x] Apply module created (`core/keymaps/apply.lua`)
- [x] Whichkey module created (`core/keymaps/whichkey.lua`)
- [x] Global mappings migrated to registry
- [x] Lazy mappings declared in registry
- [x] Buffer mappings declared in registry
- [x] Plugin-local mappings documented
- [ ] Lazy keys generated for fzf-lua (pending 02-02)
- [ ] Attach helpers for LSP (pending 02-02)
- [ ] Duplicate removal verification (pending 02-03)