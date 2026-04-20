# FAILURES.md — Runtime Failure Inventory

**Generated:** 2026-04-18T06:08:48Z
**Status:** Discovered (human-verified)

## Environment

OS: Linux 6.19.11-arch1-1 x86_64
Neovim: NVIM v0.12.1
Tools: jq: jq-1.8.1, git: git version 2.53.0

## Failure Inventory

| ID | Description | Owner | Status | Repro Steps | Provenance |
|----|-------------|-------|--------|--------------|-------------|
| BUG-001 | neo-tree plugin failed to load (module not found) | plugin | Discovered | Plugin replaced by snacks explorer in v1.0 | health |
| BUG-005 | registry keymap `<cmd> enew <CR>` has trailing characters | core/keymaps/registry.lua | **Confirmed** | Press `<leader>b` → E488 Trailing characters | manual |
| BUG-006 | registry keymap `<cmd>set wrap!<CR>` has trailing characters | core/keymaps/registry.lua | **Confirmed** | Press `<leader>lw` → E488 Trailing characters | manual |
| BUG-007 | registry keymap `<cmd>noautocmd w <CR>` has trailing characters | core/keymaps/registry.lua | **Confirmed** | Press `<leader>sn` → E488 Trailing characters | manual |
| BUG-008 | registry keymap `<cmd>enew <CR>` has trailing characters (leading space) | core/keymaps/registry.lua | **Confirmed** | Press `<leader>xs` → E488 Trailing characters | manual |
| BUG-009 | registry keymap `<C-w>v` has invalid format | core/keymaps/registry.lua | **Confirmed** | Press `<leader>v` → E488 Trailing characters | manual |
| BUG-010 | registry keymap `<C-w>s` has invalid format | core/keymaps/registry.lua | **Confirmed** | Press `<leader>h` → E488 Trailing characters | manual |
| BUG-011 | registry keymap `<C-w>=` has invalid format | core/keymaps/registry.lua | **Confirmed** | Press `<leader>se` → E488 Trailing characters | manual |
| BUG-012 | gitsigns preview_hunk not a valid function | plugins/git.lua | **Confirmed** | Press `<leader>gp` or `<leader>gt` → E488 | manual |
| BUG-013 | `<leader>f` search ignores hidden/gitignored files | plugins/fzflua.lua | **Confirmed** | fzf-lua files command needs `hidden=true` | manual |

## Summary

- **Confirmed:** 9 real bugs (keymap registry format issues, gitsigns function name, fzf-lua hidden files)
- **Discovered:** 1 (neo-tree - already replaced by snacks)
- **TODO placeholders:** 14 (not real bugs - these are feature tracking comments)

The root cause: keymap actions in registry.lua use `vim.cmd()` format strings like `"<cmd> enew <CR>"` but Neovim 0.12+ rejects trailing characters after `<CR>`.