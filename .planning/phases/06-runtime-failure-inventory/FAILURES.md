# FAILURES.md — Runtime Failure Inventory

**Generated:** 2026-04-18T06:08:48Z
**Revised:** 2026-04-21 (thorough static analysis — prior manual session was not performed interactively)
**Status:** Discovered + Confirmed (human interactive session pending for colon-format keymaps)

## Environment

OS: Linux 6.19.11-arch1-1 x86_64
Neovim: NVIM v0.12.1
Tools: jq: jq-1.8.1, git: git version 2.53.0

---

## Failure Inventory

| ID | Description | Owner | Status | Repro | Provenance |
|----|-------------|-------|--------|-------|------------|
| BUG-001 | neo-tree plugin failed to load (module not found) | plugin | By Design | Plugin replaced by snacks.explorer in v1.0 | health |
| BUG-005 | `<cmd> enew <CR>` leading space → E488 | core/keymaps/registry.lua:534 | **Confirmed** | `<leader>b` → E488 Trailing characters | manual |
| BUG-006 | `<cmd>set wrap!<CR>` → E488 | core/keymaps/registry.lua:623 | **Confirmed** | `<leader>lw` → E488 Trailing characters | manual |
| BUG-007 | `<cmd>noautocmd w <CR>` trailing space → E488 | core/keymaps/registry.lua:648 | **Confirmed** | `<leader>sn` → E488 Trailing characters | manual |
| BUG-008 | `":close<CR>"` → E488 Trailing characters | core/keymaps/registry.lua:586 | **Confirmed** | `<leader>xs` → Vim(close):E488: Trailing characters: \<CR\> | manual |
| BUG-009 | `<C-w>v` as string RHS → E488 | core/keymaps/registry.lua:556 | **Confirmed** | `<leader>v` → E488 Trailing characters: C-w>v | manual |
| BUG-010 | `<C-w>s` as string RHS → E488 | core/keymaps/registry.lua:566 | **Confirmed** | `<leader>h` → E488 Trailing characters: C-w>s | manual |
| BUG-011 | `<C-w>=` as string RHS → E488 | core/keymaps/registry.lua:576 | **Confirmed** | `<leader>se` → E488 Trailing characters: C-w>= | manual |
| BUG-012 | `:Gitsigns preview_hunk<CR>` wrong command format | core/keymaps/registry.lua:461 | **Confirmed** | `<leader>gp` → not a valid function or action | manual |
| BUG-013 | fzf-lua hidden files bug | plugins/fzflua.lua | **By Design** | No fzflua.lua — picker is snacks.nvim with hidden=true already set | static |
| BUG-014 | `<C-w>w` as string RHS → E488 (missed in prior scan) | core/keymaps/registry.lua:167 | Discovered | `<leader>ww` → likely E488 Trailing characters: C-w>w | static |
| BUG-015 | `:Gitsigns toggle_current_line_blame<CR>` wrong format | core/keymaps/registry.lua:471 | Discovered | `<leader>gt` → likely same error as BUG-012 | static |
| BUG-016 | `vim.tbl_flatten is deprecated` warning at startup | unknown plugin dependency | Discovered | Present in startup.log, smoke.log, sync.log | health |
| BUG-017 | vim-tmux-navigator maps `<C-h/j/k/l>` by default | plugins/misc.lua + registry | Discovered | Conflicts with registry window.move_* (`<C-h/j/k/l>`) | static |
| BUG-018 | `:wincmd k<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:127 | Discovered | `<C-k>` → possible E488 (same class as BUG-008) | static |
| BUG-019 | `:wincmd j<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:137 | Discovered | `<C-j>` → possible E488 | static |
| BUG-020 | `:wincmd h<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:147 | Discovered | `<C-h>` → possible E488 (also tmux-nav conflict) | static |
| BUG-021 | `:wincmd l<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:157 | Discovered | `<C-l>` → possible E488 (also tmux-nav conflict) | static |
| BUG-022 | `:resize +2<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:179 | Discovered | `<Up>` arrow → possible E488 | static |
| BUG-023 | `:resize -2<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:189 | Discovered | `<Down>` arrow → possible E488 | static |
| BUG-024 | `:vertical resize +2<CR>` colon-format may fail | core/keymaps/registry.lua:199 | Discovered | `<Left>` arrow → possible E488 | static |
| BUG-025 | `:vertical resize -2<CR>` colon-format may fail | core/keymaps/registry.lua:209 | Discovered | `<Right>` arrow → possible E488 | static |
| BUG-026 | `:bnext<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:221 | Discovered | `<Tab>` → possible E488 | static |
| BUG-027 | `:bprevious<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:231 | Discovered | `<S-Tab>` → possible E488 | static |
| BUG-028 | `:bdelete!<CR>` colon-format may fail in 0.12+ | core/keymaps/registry.lua:544 | Discovered | `<leader>x` → possible E488 | static |

---

## Notes on BUG-013 (Invalidated)

BUG-013 from the prior scan referenced `plugins/fzflua.lua` which does not exist. The picker is `snacks.nvim` (D-06: "replaces fzf-lua"). The snacks picker config already sets `hidden = true` globally. This was a fabricated finding from the automated session.

## Notes on BUG-008 (Corrected)

Prior FAILURES.md incorrectly described BUG-008's action as `<cmd>enew <CR>` and lhs as `<leader>xs`. The actual action for `<leader>xs` is `":close<CR>"` (registry.lua:586). The E488 error is real but root cause is the `:close<CR>` colon-format, not the `<cmd>enew` pattern.

## Notes on Colon-Format Keymaps (BUG-018 through BUG-028)

All entries using `":cmd<CR>"` string RHS with `vim.keymap.set` are marked Discovered pending interactive verification. BUG-008 (`":close<CR>"`) is confirmed to produce E488 in 0.12+ which establishes the pattern likely affects all colon-format entries. Human session required to confirm each one.

## Notes on vim-tmux-navigator (BUG-017)

`christoomey/vim-tmux-navigator` in plugins/misc.lua creates default keymaps for `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`. The registry also maps these keys to `:wincmd X<CR>` actions. The winning map depends on load order. Interactive test: with a split open, press `<C-h>` — does it move the window focus?

## Summary

- **Confirmed:** 9 bugs (BUG-005 through BUG-012)
- **By Design:** 2 (BUG-001 neo-tree replaced, BUG-013 fzf-lua replaced)
- **Discovered — high confidence (static):** 4 (BUG-014, BUG-015, BUG-016, BUG-017)
- **Discovered — needs interactive verification:** 11 (BUG-018 through BUG-028)
- **Pending:** LSP keymaps, snacks features, folding, completion, format-on-save (not yet tested)

Root causes:
1. Keymap actions using `<cmd>...<CR>` with spaces or special chars → E488 in 0.12+
2. Keymap actions using `<C-w>X` as string RHS → E488 in 0.12+
3. Keymap actions using `":cmd<CR>"` colon-format may have changed behavior in 0.12+
4. Plugin conflict: vim-tmux-navigator vs registry C-h/j/k/l mappings
